"""
エージェント。

## Properties
- `id::AgentId` 任意のID
- `rho::Int` 強化係数
- `nu::Int` 拡散係数
- `strategy::Function` 戦略関数。自身(`Agent`)を引数に取り、インタラクション相手に紹介するエージェント(`Vector{Agent}`)を返す。
- `urn::Vector{AgentId}` 壺
- `buffer::Vector{AgentId}` バッファ
- `history::Vector{AgentId}` 自身がインタラクションした相手の履歴
- `size::Int` 壺のサイズ
"""
mutable struct Agent
  id::AgentId
  rho::Int
  nu::Int
  strategy::Function
  urn::Vector{AgentId}
  buffer::Vector{AgentId}
  history::Vector{AgentId}
  size::Int
end

function Agent(id::Int, rho::Int, nu::Int, strategy::Function)
  return Agent(id, rho, nu, strategy, AgentId[], AgentId[], AgentId[], 0)
end
