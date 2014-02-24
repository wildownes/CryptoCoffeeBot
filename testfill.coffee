#### Sample bot showing how to input previous indicator data into a variable.             ####
#### Thanks to vkvk on https://kugutsumen.campfirenow.com/room/584930 for helping me out. ####
class Init


  @init_context: (context) ->

    context.fee              = 0.2

    context.lag              = 1
    context.period           = 20
    context.FastPeriod      = 10
    context.SlowPeriod      = 21
    context.MAType          = 3
    context.SignalPeriod    = 9

###### Here is the variable we want to fill with past data ###########


    context.prevmacd = [0, 0, 0, 0]

class functions    
  
  @macd: (data, lag, FastPeriod,SlowPeriod,SignalPeriod) ->
    results = talib.MACD
     inReal: data
     startIdx: 0
     endIdx: data.length - lag
     optInFastPeriod: FastPeriod
     optInSlowPeriod: SlowPeriod
     optInSignalPeriod: SignalPeriod
    result =
      macd: _.last(results.outMACD)
      signal: _.last(results.outMACDSignal)
      histogram: _.last(results.outMACDHist)
    result




  
init: (context) ->

  Init.init_context(context)

  

handle: (context, data)->

 

    instrument =  data.instruments[0]
    
    price      =  instrument.close[instrument.close.length - 1]
    open       =  instrument.open[instrument.open.length - 1]
    high       =  instrument.high[instrument.high.length - 1]
    low        =  instrument.low[instrument.low.length - 1]
    close      =  instrument.close[instrument.close.length - 1]
    volume     =  instrument.volumes[instrument.volumes.length - 1]
    


    macd = functions.macd(instrument.close, context.lag, context.FastPeriod,context.SlowPeriod,context.SignalPeriod)
    macdprev1 = functions.macd(instrument.close, 2, context.FastPeriod,context.SlowPeriod,context.SignalPeriod)

    warn "PAST: "+macd2.macd
    warn "CURRENT: "+macd.macd

    #warn functions.macd(instrument.close - 1, context.lag+1, context.FastPeriod,context.SlowPeriod,context.SignalPeriod)
    #warn functions.macd(instrument.close - 1, context.lag+2, context.FastPeriod,context.SlowPeriod,context.SignalPeriod)
########################################
######    Store Past Signals ###########


    context.prevmacd.push(macd.macd)
    context.prevmacd.shift()
#warn "Prev MACD: "+macd1.macd+" Curr MACD: "+macd.macd

    #warn "MACD4: "+context.prevmacd[0]+" MACD3: "+context.prevmacd[1]+" MACD2: "+context.prevmacd[2]+" MACD1: "+context.prevmacd[3]
 
    

    
    
