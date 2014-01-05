###
YOUR BOT NAME v0.1 - username / email
    BTC xxxxxxxxxxxxxxxxxxx
    LTC xxxxxxxxxxxxxxxxxxx

In this state the bot does no trades
but provides a base framework to begin a
new algorithm that includes sportpilots Stats & Orders

****Module Credits**** (PLEASE KEEP UPDATED)
Stats & Orders module v0.4.5 by sportpilot
    BTC 1561k5XqWFJSHP8apmvGt15ecWjw9ZLKGi
###


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Stats & Orders module v0.4.5 by sportpilot
# BTC - 1561k5XqWFJSHP8apmvGt15ecWjw9ZLKGi
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   Description: This module provides Statistics reporting
#     and the ability to use Limit Orders, change the
#     Trade Timeout, set curr2 limit or to set Reserves
#     for curr2 &/or curr1.
#
class Stats
  @handle: (context, data)->
    instrument = data[context.pair]
    context.last_ins = instrument
    context.last_data = data
    context.last_portfolio = portfolio
    for key, value of _.toArray(context.last_portfolio)[0]
      context.currs.push key
    if context.value_initial == 0
      Stats.initial(context, instrument, portfolio)


  @initial: (context, instrument, portfolio) ->
    positions = _.toArray(portfolio.positions)
    context.trader_curr1 = positions[0].amount
    context.trader_curr2 = positions[1].amount

    if context.trader_curr1 > 0
      context.curr1_initial = context.trader_curr1
      context.buy_value = (context.trader_curr1 * instrument.price) + context.trader_curr2
    else
      context.curr1_initial = context.trader_curr2 / instrument.price
    context.curr2_initial = context.trader_curr2
    context.price_initial = instrument.price
    context.value_initial = (instrument.price * context.trader_curr1) + context.curr2_initial

  @exec_stats: (context) ->
    if context.next_stats == 0 then context.next_stats = context.time
    if context.time >= context.next_stats
      context.next_stats += context.stats_period
      return true

  @report: (context) ->
    instrument = context.last_ins
    data = context.last_data
    context.time = data.at / 60000
    if (context.stats == 'all' and Stats.exec_stats(context)) or (context.traded and (context.stats == 'both' or context.stats =='all')) or (context.traded and context.stats == 'sell' and context.trade_type == 'sell')
      positions = _.toArray(context.last_portfolio.positions)
      context.trader_curr1 = positions[0].amount
      context.trader_curr2 = positions[1].amount
      balance = (instrument.price * context.trader_curr1) + context.trader_curr2
      if context.trade_value?
        value = context.trade_value
      else
        value = balance
      open = instrument.open[instrument.open.length - 1]
      high = instrument.high[instrument.high.length - 1]
      low = instrument.low[instrument.low.length - 1]
      gain_loss = (value - context.value_initial)
      BH_gain_loss = (value - (instrument.price * context.curr1_initial)).toFixed(2)

      if context.traded is false
        debug "~~~~~~~~~~~~~~~~~~~~~~"
      else
        debug "~"

      if context.balances
        debug "Balance (#{context.currs[1]}): #{balance.toFixed(2)} | #{context.currs[1]}: #{context.trader_curr2.toFixed(2)} | #{context.currs[0]}: #{context.trader_curr1.toFixed(5)}"
      if context.gain_loss
        if context.trader_curr1 > 0 or context.traded
          debug "[G/L] Session: #{gain_loss.toFixed(2)}  | Trade: #{(value - context.buy_value).toFixed(2)}  |  B&H: #{BH_gain_loss}"
        else
          debug "[G/L] Session: #{gain_loss.toFixed(2)}  |  B&H: #{BH_gain_loss}"

      if context.win_loss
        if context.mode == null
          debug "[W/L]: #{context.Strat1_win_cnt}/#{context.Strat1_loss_cnt} ~ #{context.Strat1_win_value.toFixed(2)}/#{context.Strat1_loss_value.toFixed(2)}"
        else
          debug "[W/L] Ichi: #{context.Strat1_win_cnt}/#{context.Strat1_loss_cnt} ~ #{context.Strat1_win_value.toFixed(2)}/#{context.Strat1_loss_value.toFixed(2)} | Scalp: #{context.Strat2_win_cnt}/#{context.Strat2_loss_cnt} ~ $#{context.Strat2_win_value.toFixed(2)}/$#{context.Strat2_loss_value.toFixed(2)}"

      if context.prices
        debug "Price: #{instrument.price.toFixed(3)} | Open: #{open.toFixed(3)} | High: #{high.toFixed(3)} | Low: #{low.toFixed(3)}"
    context.traded = false
    context.trade_value = null

#    if context.triggers and context.mode == 'ichi'
#      if context.trader_curr1 > 0
#        warn "Long - Close: #{tk_diff.toFixed(3)} >= #{config.long_close} [&] #{c.tenkan.toFixed(3)} <= #{c.kijun.toFixed(3)} [&] (#{c.chikou.toFixed(3)} <= #{sar.toFixed(3)} [or] #{rsi.toFixed(3)} <= #{config.rsi_low} [or] #{macd.histogram.toFixed(3)} <= #{config.macd_short})"
#        warn "Short - Open: #{tk_diff.toFixed(3)} >= #{config.short_open} [&] #{c.tenkan.toFixed(3)} <= #{c.kijun.toFixed(3)} [&] #{tenkan_max.toFixed(3)} <= #{kumo_min.toFixed(3)} [&] #{c.chikou_span.toFixed(3)} <= 0 [&] #{aroon.up} - #{aroon.down} < -#{config.aroon_threshold}"
#      else
#        warn "Short - Close: #{tk_diff.toFixed(3)} >= #{config.short_close} [&] #{c.tenkan.toFixed(3)} >= #{c.kijun.toFixed(3)} [&] (#{c.chikou.toFixed(3)} >= #{sar.toFixed(3)} [or] #{rsi.toFixed(3)} >= #{config.rsi_low} [or] #{macd.histogram.toFixed(3)} >= #{config.macd_long})"
#        warn "Long - Open: #{tk_diff.toFixed(3)} >= #{config.long_open} [&] #{c.tenkan.toFixed(3)} >= #{c.kijun.toFixed(3)} [&] #{tenkan_min.toFixed(3)} >= #{kumo_max.toFixed(3)} [&] #{c.chikou_span.toFixed(3)} >= 0 [&] #{aroon.up} - #{aroon.down} >= #{config.aroon_threshold}"

  @win_loss: (context, instrument, trade_result) ->
    trade_net = context.trade_value - context.buy_value
    if context.mode == 'ichi' or context.mode == null
      if trade_net >= 0
        context.Strat1_win_cnt += 1
        context.Strat1_win_value += trade_net
      else
        context.Strat1_loss_cnt += 1
        context.Strat1_loss_value += trade_net
    else if context.mode =='scalp'
      if trade_net >= 0
        context.Strat2_win_cnt += 1
        context.Strat2_win_value += trade_net
      else
        context.Strat2_loss_cnt += 1
        context.Strat2_loss_value += trade_net

  @can_buy: (context, instrument) ->
    context.trader_curr2 >= ((instrument.price * context.min_btc) * (1 + context.fee_percent / 100))

  @can_sell: (context) ->
    context.trader_curr1 >= context.min_btc

  @sell: (context, instrument, amt) ->
    if Stats.can_sell(context)
      if context.trader_curr1 - context.curr1_reserve > 0
        if _.contains(['all', 'both', 'sell'], context.stats)
          debug "~~~~~~~~~~~~"
        trade_price = instrument.price * (1 - context.sell_limit_percent / 100)
        if amt? then trade_amt = amt else trade_amount = context.trader_curr1 - context.curr1_reserve
        if trade_result = sell instrument, trade_amount, trade_price, context.sell_timeout
          context.trade_value = trade_result.amount * trade_result.price  # current value
          context.trader_curr2 += context.trade_value
          context.trader_curr1 -= trade_result.amount
          Stats.win_loss(context, instrument, trade_result)
          context.traded = true
          context.trade_type = 'sell'

  @buy: (context, instrument, amt) ->
    if Stats.can_buy(context, instrument)
      if context.trader_curr2 - context.curr2_reserve > 0
        if _.contains(['all', 'both', 'sell'], context.stats)
          debug "~~~~~~~~~~~~"
        context.buy_value = (context.trader_curr1 * instrument.price) + context.trader_curr2
        trade_price = instrument.price * (1 + context.buy_limit_percent / 100)
        if amt? then trade_amount = amt else trade_amount = (context.trader_curr2 - context.curr2_reserve) / trade_price
        if trade_result = buy instrument, trade_amount, trade_price, context.buy_timeout
          context.trade_value = trade_result.amount * trade_result.price  # current value
          context.trader_curr2 -= context.trade_value
          context.trader_curr1 += trade_result.amount
          context.traded = true
          context.trade_type = 'buy'
#
# Context for Stats
#
  @context: (context) ->
    context.stats = 'both'       # Display Stats? all = every stats period , sell = only on sells, both = only on buy or sell, off = no Stats
    context.stats_period = 120  # Display Stats only every n minutes when .stats = 'all'
    context.balances = true     # Display Balances?
    context.gain_loss = true    # Display Gain / Loss?
    context.win_loss = true     # Display Win / Loss?
    context.prices = true       # Display Prices?
  #  context.triggers = false    # Display Trade triggers? *** Temporarily disabled
  #
  # Context for Orders
  #
    context.curr1_reserve = 0         # Reserve curr1
    context.curr2_reserve = 0         # Reserve curr2
  #  context.curr2_limit = null        # curr2 Trading Limit (null = no limit) *** Temporarily disabled
  #
  # Required variables
  #   Uncomment any NOT already defined in the Host strategy code
  #
    context.pair = 'btc_usd'
    context.min_btc = 0.01
    context.fee_percent = 0.6
    context.buy_limit_percent = 0
    context.sell_limit_percent = 0
    context.buy_timeout = 10
    context.sell_timeout = 10
  #
  # DO NOT change anything below
  #
    context.next_stats = 0
    context.time = 0
    context.mins = 0
    context.trade_value = null
    context.last_ins = null
    context.last_data = null
    context.last_portfolio = null
    context.currs = []
    context.trader_curr1 = null
    context.trader_curr2 = null
    context.value_initial = 0
    context.price_initial = 0
    context.curr1_initial = 0
    context.curr2_initial = 0
    context.buy_value = null
    context.traded = false
    context.trade_type = null
    # Ichi/Scalp
    context.mode = null
    # Win & Losses
    context.Strat1_win_cnt = 0
    context.Strat1_win_value = 0
    context.Strat1_loss_cnt = 0
    context.Strat1_loss_value = 0
    context.Strat2_win_cnt = 0
    context.Strat2_win_value = 0
    context.Strat2_loss_cnt = 0
    context.Strat2_loss_value = 0
#
# Serialized Context
#
  @serialize: (context)->
    next_stats:context.next_stats
    last_ins:context.last_ins
    last_data:context.last_data
    last_portfolio:context.last_portfolio
    currs:context.currs
    trader_curr1:context.trader_curr1
    trader_curr2:context.trader_curr2
    value_initial:context.value_initial
    price_initial:context.price_initial
    curr1_initial:context.curr1_initial
    curr2_initial:context.curr2_initial
    traded:context.traded
    Strat1_win_cnt:context.Strat1_win_cnt
    Strat1_win_value:context.Strat1_win_value
    Strat1_loss_cnt:context.Strat1_loss_cnt
    Strat1_loss_value:context.Strat1_loss_value
    Strat2_win_cnt:context.Strat2_win_cnt
    Strat2_win_value:context.Strat2_win_value
    Strat2_loss_cnt:context.Strat2_loss_cnt
    Strat2_loss_value:context.Strat2_loss_value
#
# finalize: method
#
  @finalize: (context)->
    if _.contains(['all', 'both', 'sell'], context.stats)
      context.stats = 'all'
      context.stats_period = 1
      debug "~~~~~~~~~~~~~~~~~~~~~~"
      debug "~  Final Stats"
      Stats.report(context)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Initialization method called before a bot starts.
# Context object holds script data and will be passed to 'handle' method.
init: (context)->
  Stats.context(context)

#This method does what exactly?  stores persistent variables?
serialize: (context)->
  Stats.serialize(context)

# This method is called for each tick
handle: (context, data)->
  Stats.handle(context, data)
  instrument = data.instruments[0]
# Strategy algorithm's handle: method should be packaged as a class and called from here
#   for example ---> EMA10_21.handle(context, data)

  #use below as a replacement for 'sell(instrument)'
  #Stats.sell(context, instrument, null)

  #use below as a replacement for 'buy(instrument)'
  #Stats.buy(context, instrument, null)

  #Process Stats
  Stats.report(context)

# This method is only run at the end of a simulation on cryptotrader.org
finalize: (context)->
  Stats.finalize(context)
