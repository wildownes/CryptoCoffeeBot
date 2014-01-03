class Ichimoku
    constructor: (@tenkan_n = 9,@kijun_n = 26)->
        @tenkan = Array(@kijun_n)
        @kijun = Array(@kijun_n)
        @senkou_a = Array(@kijun_n * 2)
        @senkou_b = Array(@kijun_n * 2)
        @chikou = []
    put: (ins) ->
        @tenkan.push(this.calc(ins,@tenkan_n))
        @kijun.push(this.calc(ins,@kijun_n))
        @senkou_a.push((@tenkan[@tenkan.length-1] + @kijun[@kijun.length-1])/2)
        @senkou_b.push(this.calc(ins,@kijun_n * 2))
        @chikou.push(ins.close[ins.close.length - 1])
    current: ->
        c = 
            tenkan: @tenkan[@tenkan.length-1]
            kijun: @kijun[@kijun.length-1]
            senkou_a: @senkou_a[@senkou_a.length-@kijun_n]
            senkou_b: @senkou_b[@senkou_b.length-@kijun_n]
            chikou: @chikou[@chikou.length-1]
            lag_senkou_a: @senkou_a[@senkou_a.length-(@kijun_n*2)]
            lag_senkou_b: @senkou_b[@senkou_b.length-(@kijun_n*2)]
        return c
    calc: (ins,n) ->
        hh = _.max(ins.high[-n..])
        ll = _.min(ins.low[-n..])
        return (hh + ll) / 2
init: (context)->
    context.ichi = new Ichimoku()
    context.init = true
    context.pos = null
    context.open = 0.2
    context.close = 1.75
handle: (context, data)->
    # data object provides access to the current candle (ex. data['btc_usd'].close)
    instrument = data.instruments[0]
    if context.init
        for i in [0...instrument.close.length]
            t =
                open: instrument.open[..i]
                close: instrument.close[..i]
                high: instrument.high[..i]
                low: instrument.low[..i]
            context.ichi.put(t)
        context.init = false
    context.ichi.put(instrument)
    c = context.ichi.current()
    diff = 100 * ((c.tenkan - c.kijun) / ((c.tenkan + c.kijun)/2))
    diff = Math.abs(diff)
    min_tenkan = _.min([c.tenkan,c.kijun])
    max_tenkan = _.max([c.tenkan,c.kijun])
    min_senkou = _.min([c.senkou_a,c.senkou_b])
    max_senkou = _.max([c.senkou_a,c.senkou_b])
    min_lag = _.min([c.lag_senkou_a,c.lag_senkou_b])
    max_lag = _.max([c.lag_senkou_a,c.lag_senkou_b])
    if diff >= context.open
        if c.tenkan > c.kijun and min_tenkan > max_senkou and c.chikou > max_lag
            context.pos = 'long'
        else if c.tenkan < c.kijun and max_tenkan < min_senkou and c.chikou < min_lag
            context.pos = 'short'
    if diff >= context.close
        if context.pos == 'short' and c.tenkan > c.kijun
            context.pos = 'long'
        else if context.pos == 'long' and c.tenkan < c.kijun
            context.pos = 'short'
    if context.pos == 'long'
        buy(instrument)
    else if context.pos == 'short'
        sell(instrument)  
