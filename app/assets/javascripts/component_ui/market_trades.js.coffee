window.MarketTradesUI = flight.component ->
  flight.compose.mixin @, [NotificationMixin]

  @attributes
    defaultHeight: 156
    tradeSelector: 'tr'
    newTradeSelector: 'tr.new'
    allSelector: 'a.all'
    mySelector: 'a.my'
    allTableSelector: 'table.all-trades tbody'
    myTableSelector: 'table.my-trades tbody'
    newMarketTradeContent: 'table.all-trades tr.new div'
    newMyTradeContent: 'table.my-trades tr.new div'
    closeTradeButton: 'button'
    tradesLimit: 80

  @showAllTrades = (event) ->
    @select('mySelector').removeClass('active')
    @select('allSelector').addClass('active')
    @select('myTableSelector').hide()
    @select('allTableSelector').show()

  @showMyTrades = (event) ->
    @select('allSelector').removeClass('active')
    @select('mySelector').addClass('active')
    @select('allTableSelector').hide()
    @select('myTableSelector').show()

  @bufferMarketTrades = (event, data) ->
    @marketTrades = @marketTrades.concat data.trades

  @clearMarkers = (table) ->
    table.find('tr.new').removeClass('new')
    table.find('tr').slice(@attr.tradesLimit).remove()

  @notifyMyTrade = (trade) ->
    market = gon.markets[trade.market]
    message = gon.i18n.notification.new_trade
      .replace(/%{kind}/g, gon.i18n[trade.kind])
      .replace(/%{id}/g, trade.id)
      .replace(/%{price}/g, trade.price)
      .replace(/%{volume}/g, trade.volume)
      .replace(/%{base_unit}/g, market.base_unit.toUpperCase())
      .replace(/%{quote_unit}/g, market.quote_unit.toUpperCase())
    @notify message

  @isMine = (trade) ->
    return false if @myTrades.length == 0

    for t in @myTrades
      if trade.tid == t.id
        return true
      if trade.tid > t.id # @myTrades is sorted reversely
        return false

  @closeTrade = (event) ->
    $tr = $(event.target).closest('tr')
    $priceDiv = $($tr.find('td.price > div').first())
    price = parseFloat($priceDiv.text() + $priceDiv.closest('g').text())

    $volumeDiv = $($tr.find('td.volume > div').first())
    volume = parseFloat($volumeDiv.text() + $volumeDiv.closest('g').text())

    kind = $(event.target).data('kind')
    id = $tr.data('id')

    if kind == 'ask'
      url = window.location.href.split(/\?|#/)[0] + '/order_bids'
      body = {
        utf8: "✓",
        order_bid: {
          ord_type: 'limit',
          price: price,
          origin_volume: volume,
          total: price * volume,
        }
      }
    else
      url = window.location.href.split(/\?|#/)[0] + '/order_asks'
      body = {
        utf8: "✓",
        order_ask: {
          ord_type: 'limit',
          price: price,
          origin_volume: volume,
          total: price * volume,
        }
      }

    $.post(url, body)
    .then =>
      closed_trades = JSON.parse(window.localStorage.getItem('closed-trades'))
      if !(closed_trades instanceof Array)
        closed_trades = []
      closed_trades.push id
      window.localStorage.setItem('closed-trades', JSON.stringify(closed_trades))
      trade = @myTrades.find((e) -> e.id == id)
      trade.semi_closed = true
      $($tr.find('td.profit_or_loss').first()).html('')


  @handleMarketTrades = (event, data) ->
    for trade in data.trades
      @marketTrades.unshift trade
      trade.classes = 'new'
      trade.classes += ' mine' if @isMine(trade)
      el = @select('allTableSelector').prepend(JST['templates/market_trade'](trade))

    value = @currentValue()
    @updatePOL(value)

    @marketTrades = @marketTrades.slice(0, @attr.tradesLimit)
    @select('newMarketTradeContent').slideDown('slow')

    setTimeout =>
      @clearMarkers(@select('allTableSelector'))
    , 900

  @currentValue = ->
    if @myTrades[0] && (@myTrades[0].id > @marketTrades[0].tid)
      parseFloat(@myTrades[0].price)
    else
      parseFloat(@marketTrades[0].price)

  @updatePOL = (value) ->
    $('table.my-trades tr').each (index, element) =>
      if ($(element).find('td.profit_or_loss > span').first())
        $priceDiv = $($(element).find('td.price > div').first())
        $volumeDiv = $($(element).find('td.volume > div').first())
        volume = parseFloat($volumeDiv.text() + $volumeDiv.closest('g').text())
        price = parseFloat($priceDiv.text() + $priceDiv.closest('g').text())
        pol = (price - value) * volume
        $(element).find('.profit_or_loss').html(JST['templates/pol']({ profit_or_loss: pol }))

  @updateMyTrades = ->
    for trade, index in @myTrades
      if !trade.closed && trade.market == gon.market.id
        for lower in @myTrades.slice(index+1)
          if !lower.closed &&
             trade.market == lower.market &&
             trade.kind != lower.kind &&
             trade.price == lower.price &&
             trade.volume == lower.volume
            trade.closed = true
            lower.closed = true
            break

  @handleMyTrades = (event, data, notify=true) ->
    for trade in data.trades
      if trade.market == gon.market.id
        @myTrades.unshift trade

    value = @currentValue()
    @updateMyTrades()
    @updatePOL(value)
    for trade in data.trades
      if trade.market == gon.market.id
        trade.classes = 'new'

        closed_trades = JSON.parse(window.localStorage.getItem('closed-trades')) || []
        if !(trade.closed || trade.semi_closed) && !(trade.id in closed_trades)
          pol = value - parseFloat(trade.price)
          trade.profit_or_loss = pol.toString()

        el = @select('myTableSelector').prepend(JST['templates/my_trade'](trade))
        @select('allTableSelector').find("tr#market-trade-#{trade.id}").addClass('mine')

      @notifyMyTrade(trade) if notify

    @myTrades = @myTrades.slice(0, @attr.tradesLimit) if @myTrades.length > @attr.tradesLimit
    @select('newMyTradeContent').slideDown('slow')

    setTimeout =>
      @clearMarkers(@select('myTableSelector'))
    , 900

  @after 'initialize', ->
    @marketTrades = []
    @myTrades = []

    @on document, 'trade::populate', (event, data) =>
      @handleMyTrades(event, trades: data.trades.reverse(), false)
    @on document, 'trade', (event, trade) =>
      @handleMyTrades(event, trades: [trade])

    @on document, 'market::trades', @handleMarketTrades

    @on @select('allSelector'), 'click', @showAllTrades
    @on @select('mySelector'), 'click', @showMyTrades

    $(document).on('click', '.pl-close-trade-button', (e) => @closeTrade(e))
