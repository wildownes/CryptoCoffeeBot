###
BTCorbustScalp BOT v0.1 - BTCorbust
    BTC 1KvPi4XybwC6bmErQ53GDKLvrJrobK1PER

WorkingBacktest:
https://cryptotrader.org/backtests/JPTfXpnbjzXD9Gv7o

# Ichimoku/Scalp Hybrid
#
# This algorithm combines long term ichimoku and short term scalping.
# Strong bull markets and strong bear markets use ichimoku. Uncertain
# markets use scalping.
#
# Configure the trading bot period for use with short term scalping
# trades (eg. 1m, 5m, 15m).
#
# Configure context.ichi_period to the long term ichimoku period in
# minutes to be used (eg. 120 = 2hrs).
#
# MtGox 5min
#

class Ichimoku
  constructor: (@tenkan_n, @kijun_n, @senkou_a_n, @senkou_b_n, @chikou_n) ->
    @price = 0.0
    @tenkan = 0.0
    @kijun = 0.0
    @senkou_a = []
    @senkou_b = []
    @chikou = []

  # get current ichimoku state
  current: ->
    c =
      price: @price
      tenkan: @tenkan
      kijun: @kijun
      senkou_a: @senkou_a[0]
      senkou_b: @senkou_b[0]
#      chikou: @chikou[0]
      chikou: @chikou[@chikou.length - 1]
      chikou_span: @chikou[@chikou.length - 1] - @chikou[0]
    return c

  # update with latest instrument price data
  put: (ins) ->
    # update last close price
    @price = ins.close[ins.close.length - 1]
    # update tenkan sen
    @tenkan = this._hla(ins, @tenkan_n)
    # update kijun sen
    @kijun = this._hla(ins, @kijun_n)
    # update senkou span a
    @senkou_a.push((@tenkan + @kijun) / 2)
    this._splice(@senkou_a, @senkou_a_n)
    # update senkou span b
    @senkou_b.push(this._hla(ins, @senkou_b_n * 2))
    this._splice(@senkou_b, @senkou_b_n)
    # update chikou span
    @chikou.push(ins.close[ins.close.length - 1])
    this._splice(@chikou, @chikou_n)

  # calc average of price extremes (high-low avg) over specified period
  _hla: (ins, n) ->
    hh = _.max(ins.high[-n..])
    ll = _.min(ins.low[-n..])
    return (hh + ll) / 2

  # restrict array length to specified max
  _splice: (arr, l) ->
    while arr.length > l
      arr.splice(0, 1)


class HeikinAshi
  constructor: () ->
    @ins =
      open: []
      close: []
      high: []
      low: []

  # update with latest instrument price data
  put: (ins) ->
    if @ins.open.length == 0
      # initial candle
      @ins.open.push(ins.open[ins.open.length - 1])
      @ins.close.push(ins.close[ins.close.length - 1])
      @ins.high.push(ins.high[ins.high.length - 1])
      @ins.low.push(ins.low[ins.low.length - 1])
    else
      # every other candle
      prev_open = ins.open[ins.open.length - 2]
      prev_close = ins.close[ins.close.length - 2]
      curr_open = ins.open[ins.open.length - 1]
      curr_close = ins.close[ins.close.length - 1]
      curr_high = ins.high[ins.high.length - 1]
      curr_low = ins.low[ins.low.length - 1]
      @ins.open.push((prev_open + prev_close) / 2)
      @ins.close.push((curr_open + curr_close + curr_high + curr_low) / 4)
      @ins.high.push(_.max([curr_high, curr_open, curr_close]))
      @ins.low.push(_.min([curr_low, curr_open, curr_close]))


class Functions
  @diff: (x, y) ->
    ((x - y) / ((x + y) / 2)) * 100

  @ema: (data, period) ->
    results = talib.EMA
      inReal: data
      startIdx: 0
      endIdx: data.length - 1
      optInTimePeriod: period
    _.last(results)

  @sar: (high, low, accel, max) ->
    results = talib.SAR
      high: high
      low: low
      startIdx: 0
      endIdx: high.length - 1
      optInAcceleration: accel
      optInMaximum: max
    _.last(results)

  @sar_ext: (high, low, start_value, offset_on_rev, accel_init_long, accel_long, accel_max_long, accel_init_short, accel_short, accel_max_short) ->
    results = talib.SAREXT
      high: high
      low: low
      startIdx: 0
      endIdx: high.length - 1
      optInStartValue: start_value
      optInOffsetOnReverse: offset_on_rev
      optInAccelerationInitLong: accel_init_long
      optInAccelerationLong: accel_long
      optInAccelerationMaxLong: accel_max_long
      optInAccelerationInitShort: accel_init_short
      optInAccelerationShort: accel_short
      optInAccelerationMaxShort: accel_max_short
    _.last(results)

  @aroon: (high, low, period) ->
    results = talib.AROON
      high: high
      low: low
      startIdx: 0
      endIdx: high.length - 1
      optInTimePeriod: period
    result =
      up: _.last(results.outAroonUp)
      down: _.last(results.outAroonDown)
    result

  @macd: (data, fast_period, slow_period, signal_period) ->
    results = talib.MACD
      inReal: data
      startIdx: 0
      endIdx: data.length - 1
      optInFastPeriod: fast_period
      optInSlowPeriod: slow_period
      optInSignalPeriod: signal_period
    result =
      macd: _.last(results.outMACD)
      signal: _.last(results.outMACDSignal)
      histogram: _.last(results.outMACDHist)
    result

  @rsi: (data, period) ->
    results = talib.RSI
      inReal: data
      startIdx: 0
      endIdx: data.length - 1
      optInTimePeriod: period
    _.last(results)

  @populate: (target, ins, step = 1) ->
    for i in [0...ins.close.length / step]
      t =
        open: ins.open[..i]
        close: ins.close[..i]
        high: ins.high[..i]
        low: ins.low[..i]
      target.put(t)

  @can_buy: (ins, min_btc, fee_percent) ->
    portfolio.positions[ins.curr()].amount >= ((ins.price * min_btc) * (1 + fee_percent / 100))

  @can_sell: (ins, min_btc) ->
    portfolio.positions[ins.asset()].amount >= min_btc

  @buy: (instrument, limit_percent, timeout) ->
    buy(instrument, null, instrument.price * (1 + limit_percent / 100), timeout)

  @sell: (instrument, limit_percent, timeout) ->
    sell(instrument, null, instrument.price * (1 - limit_percent / 100), timeout)


class Config
  constructor: (@long_open, @long_close, @short_open, @short_close, @sar_accel, @sar_max, @aroon_period, @aroon_threshold, @macd_fast_period, @macd_slow_period, @macd_signal_period, @macd_short, @macd_long, @rsi_period, @rsi_high, @rsi_low) ->


init: (context) ->
  context.pair = 'btc_usd'
  context.min_btc = 0.01
  context.fee_percent = 0.6
  context.buy_timeout = 10
  context.sell_timeout = 10
  context.buy_limit_percent = 0
  context.sell_limit_percent = 0
  context.ha = new HeikinAshi()
  context.ichi_bull = new Ichimoku(8, 11, 11, 11, 11)
  context.ichi_bear = new Ichimoku(7, 10, 11, 11, 11)
  context.config_bull = new Config(0.1, 2.18, 0.20, 2.18, 0.025, 0.2, 10, 20, 10, 21, 8, -1, 1, 20, 52, 48)
  context.config_bear = new Config(0.1, 0.3, 0.3, 2.4, 0.025, 0.2, 10, 20, 14, 22, 9, 0, 1, 20, 52, 48)
  context.bull_market_threshold = 2
  context.bear_market_threshold = 2
  context.market_short = 12
  context.market_long = 90
  context.ichi_period = 120
  context.scalp_short = 3
  context.scalp_long = 6
  context.scalp_buy_threshold = 0.5
  context.scalp_sell_threshold = 0.1
  context.enable_ha = true
  context.mode = null
  context.pos = null
  context.init = true

handle: (context, data) ->
  # get instrument
  instrument = data[context.pair]

  # check mode
  now = new Date(instrument.ticks[instrument.ticks.length - 1].at)
  hrs = now.getHours()
  mins = now.getMinutes()
  mins_of_day = hrs * 60 + mins
  if (mins_of_day % context.ichi_period == 0)
    mode = 'ichi'
  else
    mode = 'scalp'

  # handle instrument data
  if context.init
    if context.enable_ha
      # initialise heikin-ashi
      Functions.populate(context.ha, instrument, context.ichi_period)
      # initialise ichimoku (from heikin-ashi data)
      Functions.populate(context.ichi_bull, context.ha.ins, context.ichi_period)
      Functions.populate(context.ichi_bear, context.ha.ins, context.ichi_period)
    else
      # initialise ichimoku
      Functions.populate(context.ichi_bull, instrument, context.ichi_period)
      Functions.populate(context.ichi_bear, instrument, context.ichi_period)
    # initialisation complete
    context.init = false
  else
    if mode == 'ichi'
      if context.enable_ha
        # handle new instrument (via heikin-ashi)
        context.ha.put(instrument)
        context.ichi_bull.put(context.ha.ins)
        context.ichi_bear.put(context.ha.ins)
      else
        # handle new instrument
        context.ichi_bull.put(instrument)
        context.ichi_bear.put(instrument)

  # determine setup for current market condition (bull/bear)
  if context.enable_ha
    mkt_short = Functions.ema(context.ha.ins.close, context.market_short)
    mkt_long = Functions.ema(context.ha.ins.close, context.market_long)
  else
    mkt_short = Functions.ema(instrument.close, context.market_short)
    mkt_long = Functions.ema(instrument.close, context.market_long)
  plot
    mkt_short: mkt_short
    mkt_long: mkt_long
  is_bull = Functions.diff(mkt_short, mkt_long) >= context.bull_market_threshold
  is_bear = Functions.diff(mkt_short, mkt_long) <= -context.bear_market_threshold

  # execute short term or long term trade
  if mode == 'scalp' and !is_bull and !is_bear
    # scalp mode!
    scalp_short = instrument.ema(context.scalp_short)
    scalp_long = instrument.ema(context.scalp_long)

    plot
      scalp_short: scalp_short
      scalp_long: scalp_long

    diff = 100 * (scalp_short - scalp_long) / ((scalp_short + scalp_long) / 2)
    if diff > context.scalp_buy_threshold
      if Functions.can_buy(instrument, context.min_btc, context.fee_percent)
        Functions.buy(instrument, context.buy_limit_percent, context.buy_timeout)
        debug "Scalp: long"
    else
      if diff < -context.scalp_sell_threshold
        if Functions.can_sell(instrument, context.min_btc)
          Functions.sell(instrument, context.sell_limit_percent, context.sell_timeout)
          debug "Scalp: short"

  else if mode == 'ichi' and (is_bull or is_bear)
    # ichimoku mode!
    if is_bull
      # bull market
      config = context.config_bull
      c = context.ichi_bull.current()
    else if is_bear
      # bear market
      config = context.config_bear
      c = context.ichi_bear.current()

    # log/plot data
    #  info "tenkan: " + c.tenkan + ", kijun:" + c.kijun + ", senkou_a:" + c.senkou_a + ", senkou_b:" + c.senkou_b
    plot
      tenkan: c.tenkan
      kijun: c.kijun
      senkou_a: c.senkou_a
      senkou_b: c.senkou_b

    # calc ichi indicators
    tk_diff = Math.abs(Functions.diff(c.tenkan, c.kijun))
    tenkan_min = _.min([c.tenkan, c.kijun])
    tenkan_max = _.max([c.tenkan, c.kijun])
    kumo_min = _.min([c.senkou_a, c.senkou_b])
    kumo_max = _.max([c.senkou_a, c.senkou_b])

    # calc sar indicator
    if context.enable_ha
      sar = Functions.sar(context.ha.ins.high, context.ha.ins.low, config.sar_accel, config.sar_max)
    else
      sar = Functions.sar(instrument.high, instrument.low, config.sar_accel, config.sar_max)

    # calc aroon indicator
    if context.enable_ha
      aroon = Functions.aroon(context.ha.ins.high, context.ha.ins.low, config.aroon_period)
    else
      aroon = Functions.aroon(instrument.high, instrument.low, config.aroon_period)

    # calc macd indicator
    if context.enable_ha
      macd = Functions.macd(context.ha.ins.close, config.macd_fast_period, config.macd_slow_period,
        config.macd_signal_period)
    else
      macd = Functions.macd(instrument.close, config.macd_fast_period, config.macd_slow_period,
        config.macd_signal_period)

    # calc rsi indicator
    if context.enable_ha
      rsi = Functions.rsi(context.ha.ins.close, config.rsi_period)
    else
      rsi = Functions.rsi(instrument.close, config.rsi_period)

    # close position
    if context.pos == "long" and tk_diff >= config.long_close and c.tenkan <= c.kijun and (c.chikou <= sar or rsi <= config.rsi_low or macd.histogram <= config.macd_short)
      if Functions.can_sell(instrument, context.min_btc)
        Functions.sell(instrument, context.sell_limit_percent, context.sell_timeout)
        debug "Ichimoku: long close"
      context.pos = "short"
    else if context.pos == "short" and tk_diff >= config.short_close and c.tenkan >= c.kijun and (c.chikou >= sar or rsi >= config.rsi_high or macd.histogram >= config.macd_long)
      if Functions.can_buy(instrument, context.min_btc, context.fee_percent)
        Functions.buy(instrument, context.buy_limit_percent, context.buy_timeout)
        debug "Ichimoku: short close"
      context.pos = "long"

    # open position
    if tk_diff >= config.long_open and c.tenkan >= c.kijun and tenkan_min >= kumo_max and c.chikou_span >= 0 and aroon.up - aroon.down >= config.aroon_threshold
      if Functions.can_buy(instrument, context.min_btc, context.fee_percent)
        Functions.buy(instrument, context.buy_limit_percent, context.buy_timeout)
        debug "Ichimoku: long open"
      context.pos = "long"
    else if tk_diff >= config.short_open and c.tenkan <= c.kijun and tenkan_max <= kumo_min and c.chikou_span <= 0 and aroon.up - aroon.down < -config.aroon_threshold
      if Functions.can_sell(instrument, context.min_btc)
        Functions.sell(instrument, context.sell_limit_percent, context.sell_timeout)
        debug "Ichimoku: short open"
      context.pos = "short"
