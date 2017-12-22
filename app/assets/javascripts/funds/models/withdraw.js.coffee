class Withdraw extends PeatioModel.Model
  @configure 'Withdraw', 'sn', 'account_id', 'member_id', 'currency', 'amount', 'fee', 'fund_uid', 'fund_extra',
    'created_at', 'updated_at', 'done_at', 'txid', 'blockchain_url', 'aasm_state', 'sum', 'type', 'is_submitting'

  constructor: ->
    super
    @is_submitting = @aasm_state == "submitting"

  @initData: (records) ->
    PeatioModel.Ajax.disable ->
      $.each records, (idx, record) ->
        Withdraw.create(record)

  afterScope: ->
    "#{@pathName()}"

  pathName: ->
    switch @currency
      when 'eur' then 'banks'
      when 'btc' then 'satoshis'
      when 'ltc' then 'litecoins'
      when 'ppc' then 'peercoins'
      when 'blk' then 'blackcoins'
      when 'rpt' then 'realpointcoins'
      when 'trt' then 'tritiumcoins'

window.Withdraw = Withdraw
