# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Stats & Orders module v0.4.8 by sportpilot
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
  @handle: (context, data)->
    context.cur_ins = data[context.pair]
    context.cur_data = data
    context.cur_portfolio = portfolio
    for key, value of _.toArray(context.cur_portfolio)[0]
      context.currs.push key
    if context.value_initial == 0
      Stats.initial(context)


  @initial: (context) ->
    positions = _.toArray(context.cur_portfolio.positions)
    context.trader_curr1 = positions[0].amount
    context.trader_curr2 = positions[1].amount

    if context.trader_curr1 > 0
      context.curr1_initial = context.trader_curr1
      context.buy_value = (context.trader_curr1 * context.cur_ins.price) + context.trader_curr2
    else
      context.curr1_initial = context.trader_curr2 / context.cur_ins.price
    context.curr2_initial = context.trader_curr2
    context.price_initial = context.cur_ins.price
    context.value_initial = (context.cur_ins.price * context.trader_curr1) + context.curr2_initial

  @exec_stats: (context) ->
    if context.next_stats == 0 then context.next_stats = context.time
    if context.time >= context.next_stats
      context.next_stats += context.stats_period
      return true

  @report: (context) ->
    data = context.cur_data
    context.time = data.at / 60000
    if (context.stats == 'all' and Stats.exec_stats(context)) or (context.traded and (context.stats == 'both' or context.stats =='all')) or (context.traded and context.stats == 'sell' and context.trade_type == 'sell')
      positions = _.toArray(context.cur_portfolio.positions)
      context.trader_curr1 = positions[0].amount
      context.trader_curr2 = positions[1].amount
      balance = (context.cur_ins.price * context.trader_curr1) + context.trader_curr2
      if not context.trade_value? or _.contains(['buy_amt', 'sell_amt'], context.trade_type)
        value = balance
      else
        value = context.trade_value
      open = context.cur_ins.open[context.cur_ins.open.length - 1]
      high = context.cur_ins.high[context.cur_ins.high.length - 1]
      low = context.cur_ins.low[context.cur_ins.low.length - 1]
      gain_loss = (value - context.value_initial)
      BH_gain_loss = (value - (context.cur_ins.price * context.curr1_initial)).toFixed(2)

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
        debug "Price: #{context.cur_ins.price.toFixed(3)} | Open: #{open.toFixed(3)} | High: #{high.toFixed(3)} | Low: #{low.toFixed(3)}"
    context.traded = false
    context.trade_value = null

#    if context.triggers and context.mode == 'ichi'
#      if context.trader_curr1 > 0
#        warn "Long - Close: #{tk_diff.toFixed(3)} >= #{config.long_close} [&] #{c.tenkan.toFixed(3)} <= #{c.kijun.toFixed(3)} [&] (#{c.chikou.toFixed(3)} <= #{sar.toFixed(3)} [or] #{rsi.toFixed(3)} <= #{config.rsi_low} [or] #{macd.histogram.toFixed(3)} <= #{config.macd_short})"
#        warn "Short - Open: #{tk_diff.toFixed(3)} >= #{config.short_open} [&] #{c.tenkan.toFixed(3)} <= #{c.kijun.toFixed(3)} [&] #{tenkan_max.toFixed(3)} <= #{kumo_min.toFixed(3)} [&] #{c.chikou_span.toFixed(3)} <= 0 [&] #{aroon.up} - #{aroon.down} < -#{config.aroon_threshold}"
#      else
#        warn "Short - Close: #{tk_diff.toFixed(3)} >= #{config.short_close} [&] #{c.tenkan.toFixed(3)} >= #{c.kijun.toFixed(3)} [&] (#{c.chikou.toFixed(3)} >= #{sar.toFixed(3)} [or] #{rsi.toFixed(3)} >= #{config.rsi_low} [or] #{macd.histogram.toFixed(3)} >= #{config.macd_long})"
#        warn "Long - Open: #{tk_diff.toFixed(3)} >= #{config.long_open} [&] #{c.tenkan.toFixed(3)} >= #{c.kijun.toFixed(3)} [&] #{tenkan_min.toFixed(3)} >= #{kumo_max.toFixed(3)} [&] #{c.chikou_span.toFixed(3)} >= 0 [&] #{aroon.up} - #{aroon.down} >= #{config.aroon_threshold}"

  @win_loss: (context, trade_result) ->
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

  @can_buy: (context) ->
    context.trader_curr2 >= ((context.cur_ins.price * context.min_btc) * (1 + context.fee_percent / 100))

  @can_sell: (context) ->
    context.trader_curr1 >= context.min_btc

  @sell: (context, amt = null) ->
    if Stats.can_sell(context)
      if context.trader_curr1 - context.curr1_reserve > 0
        if _.contains(['all', 'both', 'sell'], context.stats)
          debug "~~~~~~~~~~~~"
        trade_price = context.cur_ins.price * (1 - context.sell_limit_percent / 100)
        if amt?
          trade_amount = _.min([amt, context.trader_curr1 - context.curr1_reserve])
        else
          trade_amount = context.trader_curr1 - context.curr1_reserve
        if context.trade_emails then sendEmail("Attempting a SELL of #{trade_amount} #{context.currs[0]} at #{trade_price} #{context.currs[1]} with a timeout of #{context.sell_timeout}")
        if trade_result = sell context.cur_ins, trade_amount, trade_price, context.sell_timeout
          if context.trade_emails then sendEmail("SELL completed - #{trade_result.amount} #{context.currs[0]} at #{trade_result.price}")
          context.trade_value = trade_result.amount * trade_result.price
          context.trader_curr2 += context.trade_value
          context.trader_curr1 -= trade_result.amount
          Stats.win_loss(context, trade_result)
          context.traded = true
          if amt? then context.trade_type = 'sell_amt' else context.trade_type = 'sell'
        else
          sendEmail("SELL Failed")

  @buy: (context, amt = null) ->
    if Stats.can_buy(context)
      if context.trader_curr2 - context.curr2_reserve > 0
        if _.contains(['all', 'both', 'sell'], context.stats)
          debug "~~~~~~~~~~~~"
        context.buy_value = (context.trader_curr1 * context.cur_ins.price) + context.trader_curr2
        trade_price = context.cur_ins.price * (1 + context.buy_limit_percent / 100)
        if amt?
          trade_amount = _.min([amt * trade_price, context.trader_curr2 - context.curr2_reserve]) / trade_price
        else
          trade_amount = (context.trader_curr2 - context.curr2_reserve) / trade_price
        if context.trade_emails then sendEmail("Attempting a BUY of #{trade_amount} #{context.currs[0]} at #{trade_price} #{context.currs[1]} with a timeout of #{context.buy_timeout}")
        if trade_result = buy context.cur_ins, trade_amount, trade_price, context.buy_timeout
          if context.trade_emails then sendEmail("BUY completed - #{trade_result.amount} #{context.currs[0]} at #{trade_result.price}")
          context.trade_value = trade_result.amount * trade_result.price
          context.trader_curr2 -= context.trade_value
          context.trader_curr1 += trade_result.amount
          context.traded = true
          if amt? then context.trade_type = 'buy_amt' else context.trade_type = 'buy'
        else
          sendEmail("BUY Failed")
#
# Context for Stats
#
  @context: (context) ->
    context.stats = 'all'         # Display Stats? all = every stats period , sell = only on sells, both = only on buy or sell, off = no Stats
    context.stats_period = 120    # Display Stats only every n minutes when .stats = 'all'
    context.trade_emails = true   # Send an Email when a trade is attempted and another when it completes or fails (Live only)
    context.balances = true       # Display Balances?
    context.gain_loss = true      # Display Gain / Loss?
    context.win_loss = true       # Display Win / Loss?
    context.prices = true         # Display Prices?
  #  context.triggers = false     # Display Trade triggers? *** Temporarily disabled
  #
  # Context for Orders
  #
    context.curr1_reserve = 0         # Reserve curr1
    context.curr2_reserve = 0         # Reserve curr2
  #  context.curr2_limit = null        # curr2 Trading Limit (null = no limit) *** Temporarily disabled
  #
  # Required variables
  #   Comment any defined in the Host strategy code. The values listed here will
  #     overwritten if they are later redefined by other code.
  #
    context.pair = 'btc_usd'
    context.min_btc = 0.01
    context.fee_percent = 0.6
    context.buy_limit_percent = 0
    context.sell_limit_percent = 0
    context.buy_timeout = null
    context.sell_timeout = null
  #
  # DO NOT change anything below
  #
    context.next_stats = 0
    context.time = 0
    context.mins = 0
    context.trade_value = null
    context.cur_ins = null
    context.cur_data = null
    context.cur_portfolio = null
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
    cur_ins:context.cur_ins
    cur_data:context.cur_data
    cur_portfolio:context.cur_portfolio
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
      context.next_stats = 0
      debug "~~~~~~~~~~~~~~~~~~~~~~"
      debug "~  Final Stats"
      Stats.report(context)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Stats & Orders module v0.4.8 by sportpilot
#
# context: method
#
#   Installation: Replace -->   context: (context)->
#     with a copy of this block
#
init: (context)->
  Stats.context(context)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Stats & Orders module v0.4.8 by sportpilot
#
# serialize: method
#
#   Installation: Replace -->   serialize: (context)->
#     with a copy of this block
#
serialize: (context)->
  Stats.serialize(context)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Stats & Orders module v0.4.8 by sportpilot
#
# handle: method
#
#   Installation: Replace -->   handle: (context, data)->
#     with a copy of this block
#
handle: (context, data)->
  Stats.handle(context, data)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Stats & Orders module v0.4.8 by sportpilot
#
# sell() method - with optional (, amount) parameter
#
#   Installation: Replace ALL instances (3) of:
# -->   Functions.sell(instrument, context.sell_limit_percent, context.sell_timeout)
#     with a copy of this block
# OR
# -->   sell(instrument)
#
#   NOTE: Pay attention to the indentation of the code
#           line. It must be adjusted for your host code.
#
  Stats.sell context
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Stats & Orders module v0.4.8 by sportpilot
#
# buy() method - with optional (, amount) parameter
#
#   Installation: Replace ALL instances of:
# -->   Functions.buy(instrument, context.buy_limit_percent, context.buy_timeout)
# OR
# -->   buy(instrument)
#     with a copy of this block
#
#   NOTE: Pay attention to the indentation of the code
#           line. It must be adjusted for your host code.
#
  Stats.buy context
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Stats & Orders module v0.4.8 by sportpilot
#
# Process Stats
#
#   Installation: Paste this block at the end of ALL
#     other code or just BEFORE the finalize: method
#     if it exists.
#
#   NOTE: Pay attention to the indentation of the code
#           line. It must be adjusted for your host code.
#
  Stats.report(context)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Stats & Orders module v0.4.8 by sportpilot
#
# finalize: method
#
#   Installation: Replace: -->   finalize: (context)->
#     with a copy of this block
#
finalize: (context)->
  Stats.finalize(context)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
