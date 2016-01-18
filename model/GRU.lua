local GRU = {}

local ok, cunn = pcall(require, 'fbcunn')
if not ok then
    LookupTable = nn.LookupTable
else
    LookupTable = nn.LookupTableGPU
end

function GRU.gru(dim_word, rnn_size, num_layer, dropout, vec_size, vocab_size)
    dropout = dropout or 0 
    local has_vec = 0
    if vec_size > 0 then has_vec = 1 end

    -- inputs: there are n+1+has_vec inputs (hiddens on each layer and x. and sentence vector if it is decoder)
    local inputs = {}
    if vec_size > 0 then 
        table.insert(inputs, nn.Identity()()) -- vec_size, decoder only
    end
    table.insert(inputs, nn.Identity()()) -- x
    for L = 1,num_layer do
        table.insert(inputs, nn.Identity()()) -- prev_h[L]
    end

    -- a helper function
    function new_input_sum(insize, xv, hv)
        local i2h = nn.Linear(insize, rnn_size)(xv)
        local h2h = nn.Linear(rnn_size, rnn_size)(hv)
        return nn.CAddTable()({i2h, h2h})
    end

    -- embedding layer
    local word_vec_layer = LookupTable(vocab_size, dim_word)
    word_vec_layer.name = 'word_vecs' -- change name so we can refer to it easily later

    -- forward through each layer
    local outputs = {}
    for L = 1,num_layer do
        local x, input_size_L
        local prev_h = inputs[L+1+has_vec]
        -- the input to this layer
        if L == 1 then 
            if has_vec > 0 then
                word_vec = word_vec_layer(inputs[2])
                x = nn.JoinTable(2)({nn.Identity()(inputs[1]), word_vec})
                input_size_L = vec_size + dim_word
            else
                x = word_vec_layer(inputs[1])
                input_size_L = dim_word
            end
        else 
            x = outputs[(L-1)] 
            if dropout > 0 then x = nn.Dropout(dropout)(x) end -- apply dropout, if any
            input_size_L = rnn_size
        end
        -- GRU tick
        -- forward the update and reset gates
        local update_gate = nn.Sigmoid()(new_input_sum(input_size_L, x, prev_h))
        local reset_gate = nn.Sigmoid()(new_input_sum(input_size_L, x, prev_h))
        -- compute candidate hidden state
        local gated_hidden = nn.CMulTable()({reset_gate, prev_h})
        local p2 = nn.Linear(rnn_size, rnn_size)(gated_hidden)
        local p1 = nn.Linear(input_size_L, rnn_size)(x)
        local hidden_candidate = nn.Tanh()(nn.CAddTable()({p1,p2}))
        -- compute new interpolated hidden state, based on the update gate
        local zh = nn.CMulTable()({update_gate, hidden_candidate})
        local zhm1 = nn.CMulTable()({nn.AddConstant(1,false)(nn.MulConstant(-1,false)(update_gate)), prev_h})
        local next_h = nn.CAddTable()({zh, zhm1})
        table.insert(outputs, next_h)
    end

    -- set up the decoder
    if vec_size > 0 then
        local top_h = outputs[#outputs]
        if dropout > 0 then top_h = nn.Dropout(dropout)(top_h) end
        local proj = nn.Linear(rnn_size, vocab_size)(top_h)
        local logsoft = nn.LogSoftMax()(proj)
        table.insert(outputs, logsoft)
    end
    return nn.gModule(inputs, outputs)
end

return GRU
