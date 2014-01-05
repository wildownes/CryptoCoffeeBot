# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Stats & Orders module v0.4.2 by sportpilot
#
#   Donations: 1561k5XqWFJSHP8apmvGt15ecWjw9ZLKGi
#
#   Description: This module provides Statistics reporting
#     and the ability to use Limit Orders, change the
#     Trade Timeout, set USD limit or to set Reserves
#     for USD &/or BTC.
#
#   Ref: https://cryptotrader.org/topics/332486/stats-orders-module-v0-3-1
#   Usage: for inclusion in latest Ichi-Scalp
#
# Functions code block
#   Installation: Paste this block just BEFORE the
#     init: method
#
class Stats
  @less_fee: (v) -> v * (1 - (context.fee_percent / 100))

  @initial: (context, instrument, portfolio) ->
    context.trader_USD = portfolio.positions.usd.amount
    context.trader_BTC = portfolio.positions.btc.amount

    if context.trader_BTC > 0
      context.BTC_initial = context.trader_BTC
      context.buy_value = (context.trader_BTC * instrument.price) + context.trader_USD
    else
      context.BTC_initial = context.trader_USD / instrument.price
    context.USD_initial = context.trader_USD
    context.price_initial = instrument.price
    context.value_initial = (instrument.price * context.trader_BTC) + context.USD_initial

  @exec_time: (context, instrument) ->
    now = new Date(instrument.ticks[instrument.ticks.length - 1].at)
    hrs = now.getHours()
    mins = now.getMinutes()
    mins_of_day = hrs * 60 + mins
    period_in_min = (instrument.ticks[2].at - instrument.ticks[1].at) / 60000
    if (mins_of_day % (context.stats_period * period_in_min) == 0)
      return true

  @report: (context, instrument) ->
    if (context.stats == 'all' and Stats.exec_time(context, instrument)) or (context.traded and (context.stats == 'both' or context.stats =='all')) or (context.traded and context.stats == 'sell' and context.trade_type == 'sell')
#      if not context.traded
      context.trader_USD = portfolio.positions.usd.amount
      context.trader_BTC = portfolio.positions.btc.amount
      balance = (instrument.price * context.trader_BTC) + context.trader_USD
      if context.trade_value?
        value = context.trade_value
      else
        value = balance
      open = instrument.open[instrument.open.length - 1]
      high = instrument.high[instrument.high.length - 1]
      low = instrument.low[instrument.low.length - 1]
      gain_loss = (value - context.value_initial)
      BH_gain_loss = (value - (instrument.price * context.BTC_initial)).toFixed(2)

      if context.traded is false
        debug "~~~~~~~~~~~~~~~~~~~~~~"
      else
        debug "~"

      if context.balances
        debug "Balance: #{balance.toFixed(2)} | USD: #{context.trader_USD.toFixed(2)} | BTC: #{context.trader_BTC.toFixed(5)}"
#        debug "Trade Val: #{context.trade_value} | Buy Val: #{context.buy_value}"
      if context.gain_loss
        if context.trader_BTC > 0 or context.traded
          debug "[G/L] Session: #{gain_loss.toFixed(2)}  | Trade: #{(value - context.buy_value).toFixed(2)}  |  B&H: #{BH_gain_loss}"
        else
          debug "[G/L] Session: #{gain_loss.toFixed(2)}  |  B&H: #{BH_gain_loss}"

      if context.win_loss
        if context.mode == null
          debug "[W/L]: #{context.Strat1_win_cnt}/#{context.Strat1_loss_cnt} ~ $#{context.Strat1_win_value.toFixed(2)}/$#{context.Strat1_loss_value.toFixed(2)}"
        else
          debug "[W/L] Ichi: #{context.Strat1_win_cnt}/#{context.Strat1_loss_cnt} ~ $#{context.Strat1_win_value.toFixed(2)}/$#{context.Strat1_loss_value.toFixed(2)} | Scalp: #{context.Strat2_win_cnt}/#{context.Strat2_loss_cnt} ~ $#{context.Strat2_win_value.toFixed(2)}/$#{context.Strat2_loss_value.toFixed(2)}"

      if context.prices
        debug "Price: #{instrument.price.toFixed(3)} | Open: #{open.toFixed(3)} | High: #{high.toFixed(3)} | Low: #{low.toFixed(3)}"
    context.traded = false
    context.trade_value = null

#    if context.triggers and context.mode == 'ichi'
#      if context.trader_BTC > 0
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
    context.trader_USD >= ((instrument.price * context.min_btc) * (1 + context.fee_percent / 100))

  @can_sell: (context) ->
    context.trader_BTC >= context.min_btc

  @sell: (context, instrument) ->
    if Stats.can_sell(context)
      if context.trader_BTC - context.BTC_reserve > 0
        if _.contains(['all', 'both', 'sell'], context.stats)
          debug "~~~~~~~~~~~~"
        trade_price = instrument.price * (1 - context.sell_limit_percent / 100)
        trade_amount = context.trader_BTC - context.BTC_reserve
        if trade_result = sell instrument, trade_amount, trade_price, context.sell_timeout
          context.trade_value = trade_result.amount * trade_result.price  # current value
          context.trader_USD += context.trade_value
          context.trader_BTC -= trade_result.amount
          Stats.win_loss(context, instrument, trade_result)
          context.traded = true
          context.trade_type = 'sell'

  @buy: (context, instrument) ->
    if Stats.can_buy(context, instrument)
      if context.trader_USD - context.USD_reserve > 0
        if _.contains(['all', 'both', 'sell'], context.stats)
          debug "~~~~~~~~~~~~"
        context.buy_value = (context.trader_BTC * instrument.price) + context.trader_USD
        trade_price = instrument.price * (1 + context.buy_limit_percent / 100)
        trade_amount = (context.trader_USD - context.USD_reserve) / trade_price
        if trade_result = buy instrument, trade_amount, trade_price, context.buy_timeout
          context.trade_value = trade_result.amount * trade_result.price  # current value
          context.trader_USD -= context.trade_value
#          context.trader_USD -= context.trader_USD - context.USD_reserve
          context.trader_BTC += trade_result.amount
#          context.trade_value = (trade_result.amount * trade_result.price)  # current value
          context.traded = true
          context.trade_type = 'buy'
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Stats & Orders module v0.4.2 by sportpilot
#
# Context code block
#
#   Installation: Paste this block in the init: method
#     after the other context declarations but before
#     the handle: method. Review the settings below,
#     All options except Basic Stats are disabled by default.
#
# Context for Stats
#
  context.stats = 'both'      # Display Stats? all = every stats period , sell = only on sells, both = only on buy or sell, off = no Stats
  context.stats_period = 1    # Display Stats only every nth period when .stats = 'all'
  context.balances = true     # Display Balances?
  context.gain_loss = true    # Display Gain / Loss?
  context.win_loss = true     # Display Win / Loss?
  context.prices = true       # Display Prices?
#  context.triggers = false    # Display Trade triggers? *** Temporarily disabled
#
# Context for Orders
#
  context.BTC_reserve = 0         # Reserve BTC
  context.USD_reserve = 0         # Reserve USD
#  context.USD_limit = null        # USD Trading Limit (null = no limit) *** Temporarily disabled
#
# Required variables
#   Uncomment any NOT already defined in the Host strategy code
#
#  context.min_btc = 0.01
#  context.fee_percent = 0.6
#  context.buy_limit_percent = 0
#  context.sell_limit_percent = 0
#  context.buy_timeout = 10
#  context.sell_timeout = 10
#
# DO NOT change anything below
#
  context.trade_value = null
  context.last_ins = null
  context.trader_USD = null
  context.trader_BTC = null
  context.value_initial = 0
  context.price_initial = 0
  context.BTC_initial = 0
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
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Stats & Orders module v0.4.2 by sportpilot
#
# Serialized Context code block
#
#   Installation: Paste this block in the serialize: method
#     after the other declarations but before the
#     handle: method. If the serialize: method doesn't
#     exist, uncomment the serialize: (content)-> line
#
serialize: (context)->       # uncomment to add serialze: method
  last_ins:context.last_ins
  trader_USD:context.trader_USD
  trader_BTC:context.trader_BTC
  value_initial:context.value_initial
  price_initial:context.price_initial
  BTC_initial:context.BTC_initial
  buy_value:context.buy_value
  traded:context.traded
  Strat1_win_cnt:context.Strat1_win_cnt
  Strat1_win_value:context.Strat1_win_value
  Strat1_loss_cnt:context.Strat1_loss_cnt
  Strat1_loss_value:context.Strat1_loss_value
  Strat2_win_cnt:context.Strat2_win_cnt
  Strat2_win_value:context.Strat2_win_value
  Strat2_loss_cnt:context.Strat2_loss_cnt
  Strat2_loss_value:context.Strat2_loss_value
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Stats & Orders module v0.4.2 by sportpilot
#
# Instrument Data code block
#
#   Installation: Paste this block just BEFORE the
#      "# handle instrument data" comment.
#
  # Initialization
  if context.value_initial == 0
    Stats.initial(context, instrument, portfolio)
  context.last_ins = instrument
  if mode?      # check for Ichi/Scalp
    context.mode = mode
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Stats & Orders module v0.4.2 by sportpilot
#
# Orders - Sell() method
#
#   Installation: Replace ALL instances (3) of:
# -->   Functions.sell(instrument, context.sell_limit_percent, context.sell_timeout)
#     with a copy of this block
#
#   NOTE: Pay attention to the indentation of the code
#           line. It must be adjusted for your host code.
#
        Stats.sell(context, instrument)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Stats & Orders module v0.4.2 by sportpilot
#
# Orders - Buy() method
#
#   Installation: Replace ALL instances (3) of:
# -->   Functions.buy(instrument, context.buy_limit_percent, context.buy_timeout)
#     with a copy of this block
#
#   NOTE: Pay attention to the indentation of the code
#           line. It must be adjusted for your host code.
#
        Stats.buy(context, instrument)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Stats & Orders module v0.4.2 by sportpilot
#
# Reporting code block
#
#   Installation: Paste this block AFTER ALL other
#      code.
#
  Stats.report(context, instrument)

finalize: (context)->
  instrument = context.last_ins
  if _.contains(['all', 'both', 'sell'], context.stats)
    context.stats = 'all'
    context.stats_period = 1
    debug "~~~~~~~~~~~~~~~~~~~~~~"
    debug "~  Final Stats"
    Stats.report(context, instrument)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
