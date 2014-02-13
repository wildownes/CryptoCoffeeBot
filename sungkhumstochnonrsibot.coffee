###########################################################  
#                                                         #
# Sungkhum Stoch/MACD Bot 1.0                             #
# BTC: 1Pu3a4kNEPYiszh8xFv3x7JqWrpbDs28XK                 #
#                                                         #
# Using Thanasis full working framework                   #
# Thanasis BTC: 1CRSH4LGGRWVWqgwfquky2Rk5eJK6gsyus        #
#                                                         #
###########################################################

class Init

########################################
#### define basic constants ############

  @init_context: (context) ->

    context.fee              = 0.2

    context.lag              = 1
    context.period           = 20
    context.FastPeriod      = 10
    context.SlowPeriod      = 21
    context.MAType          = 3
    context.SignalPeriod    = 9
    context.fastK_period = 3
    context.slowK_period = 14
    context.slowK_MAType = 3
    context.slowD_period = 14
    context.slowD_MAType = 3
    context.fastD_period = 3
    context.fastD_MAType = 3

    context.mystochK = 100
    context.myzero = 0
    
 

###### Serialized constants - don't touch bellow ###########

    
    context.price_buy                 =   0
    context.price_sell                =   0 
    context.first_price               =   0
    context.number_of_orders          =   0
    context.have_fiat                 =   null
    context.have_coins                =   null
    context.commisions_paid           =   0
    context.price_of_last_order       =   null
    context.last_action_was           =   null
	
    context.prev_d = [10, 10, 10, 10]
    context.prev_k = [30, 30, 30, 30]

    context.prevmacd = [0, 0, 0, 0]
    context.prevmacdsig = [0, 0, 0, 0]

    context.sellcount = 1
    context.selltrue = false
    context.buytrue = false
    context.KrsiZero = false
    

#################################################################################

class functions

########################################
#### basic functions #############

  @diff: (x, y) ->
    (( x - y ) / (( x + y ) / 2)) * 100
    
  @percent: (x,y) ->

    (( x - y ) / y) * 100
    
  @norm_growth: (a,x) ->

    1 - Math.exp( - a * x )
    

########################################
####### indicatots ##################### 




  
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
 
  @stoch: (high,low,close,lag,fastK_period,slowK_period, slowK_MAType,slowD_period,slowD_MAType) ->
    results = talib.STOCH
      high: high
      low: low
      close: close
      startIdx: 0
      endIdx: high.length - lag
      optInFastK_Period: fastK_period
      optInSlowK_Period: slowK_period
      optInSlowK_MAType: slowK_MAType 
      optInSlowD_Period: slowD_period
      optInSlowD_MAType: slowD_MAType
    result =
      K: _.last(results.outSlowK)
      D: _.last(results.outSlowD)
    result  

  @stochrsi: (data, lag, period, fastK_period,fastD_period,fastD_MAType) ->
    results = talib.STOCHRSI
      inReal: data
      startIdx: 0
      endIdx: data.length - lag
      optInTimePeriod: period
      optInFastK_Period: fastK_period
      optInFastD_Period: fastD_period
      optInFastD_MAType: fastD_MAType
    result =
      K: _.last(results.outFastK)
      D: _.last(results.outFastD)
    result
 
#################################################################################

  
init: (context) ->

  Init.init_context(context)

#################################################################################

serialize: (context)->
    
    price_of_last_order =   context.price_of_last_order   
    context.price_buy   =   context.price_buy
    context.price_sell  =   context.price_sell
    number_of_orders    =   context.number_of_orders 
    have_fiat           =   context.have_fiat
    have_coins          =   context.have_coins 
    first_price         =   context.first_price
    first_price_found   =   context.first_price_found
    first_capital       =   context.first_capital
    commisions_paid     =   context.commisions_paid
    last_action_was     =   context.last_action_was
    
  
#################################################################################

handle: (context, data)->

 
########################################
####### define instrument ##############

    instrument =  data.instruments[0]
    
    price      =  instrument.close[instrument.close.length - 1]
    open       =  instrument.open[instrument.open.length - 1]
    high       =  instrument.high[instrument.high.length - 1]
    low        =  instrument.low[instrument.low.length - 1]
    close      =  instrument.close[instrument.close.length - 1]
    volume     =  instrument.volumes[instrument.volumes.length - 1]
    
    price_lag  =  instrument.close[instrument.close.length - context.lag]
    open_lag   =  instrument.open[instrument.open.length - context.lag]
    high_lag   =  instrument.high[instrument.high.length - context.lag]
    low_lag    =  instrument.low[instrument.low.length - context.lag]
    close_lag  =  instrument.close[instrument.close.length - context.lag]
    volume_lag =  instrument.volumes[instrument.volumes.length - context.lag]

########################################
##### calculate capital ################    

    
    unless context.first_price_found
      context.first_price           =  price
      fiat                          =  portfolio.positions[instrument.curr()].amount
      coins                         =  portfolio.positions[instrument.asset()].amount
      context.first_capital         =  fiat + coins * price
      last_action_was               =  null
      maximum = Math.max(fiat, coins * price)
      if maximum = fiat
         context.have_fiat          = true
         context.have_coins         = false 
      else 
         context.have_fiat          = false
         context.have_coins         = true  
      context.first_price_found     =  true
    
    fiat     =  portfolio.positions[instrument.curr()].amount
    coins    =  portfolio.positions[instrument.asset()].amount
    capital  =  fiat + coins * price

    
    
   

########################################
##### define basic functions ###########

    #high_low_percent = functions.percent(high, low)



########################################
##### define indicator functions ####### 


    stoch = functions.stoch(instrument.high,instrument.low,instrument.close,context.lag,context.fastK_period,context.slowK_period, context.slowK_MAType,context.slowD_period,context.slowD_MAType)

  
    macd = functions.macd(instrument.close, context.lag, context.FastPeriod,context.SlowPeriod,context.SignalPeriod)
    stochrsi = functions.stochrsi(instrument.close,context.lag,context.period,context.fastK_period,context.fastD_period,context.fastD_MAType) 
   
###########################################
######    debug indicators ################ 
    
    #debug "#{stoch.K} #{stoch.D}" 
    #debug "#{macd.macd}  #{macd.signal}  #{macd.histogram}"

    #warn "#{stochrsi.K}#{stochrsi.D} "

  
########################################
######    Get Ready signals ################

    context.mystochK = stoch.K
    
########################################
######    More Ready signals ################

    if context.mystochK < 1
       context.KrsiZero = true

########################################
######    Store Past signals ################

    context.prev_d.push(stoch.D)
    context.prev_d.shift()

    context.prev_k.push(stoch.K)
    context.prev_k.shift()

    context.prevmacd.push(macd.macd)
    context.prevmacd.shift()

    context.prevmacdsig.push(macd.signal)
    context.prevmacdsig.shift()


    
########################################
######    buy or sell Strategy #########

    if (context.prev_d[2] < context.prev_k[2] and stoch.D > stoch.K)
        context.selltrue = true
        context.sellcount = (context.sellcount + 1)
        context.buytrue = false
        #warn "SELL is TRUE"


    if (context.KrsiZero and context.prev_d[2] > context.prev_k[2] and stoch.D < stoch.K)
        context.buytrue = true
        context.selltrue = false
        context.sellcount = 1
        #warn "BUY is TRUE"
        

 

    if (stoch.D < stoch.K) and (macd.macd - context.prevmacd[2]) > 1 and stoch.D < 40#context.buytrue #and (macd.macd - context.prevmacd[2]) > 1 and stoch.D < stoch.K      ## you must write here your own condition to buy
 
        ######  don't touch bellow #####
        if context.have_fiat
           buy instrument
           context.number_of_orders    =  context.number_of_orders + 1
           context.price_buy           =  price
           context.commisions_paid     =  context.commisions_paid + context.fee * capital / 100
           context.price_of_last_order =  context.price_buy
           context.last_action_was     =  "buy"
           context.have_coins          =  true
           context.have_fiat           =  false
           context.KrsiZero = false
           context.selltrue = false
           context.buytrue = false
           context.sellcount = 1

           #warn "MACD for BUY >1: "+(macd.macd - context.prevmacd[2])

    else if macd.macd > macd.signal and context.prevmacd[2] < context.prevmacdsig[2]      ## you must write here your own condition to buy
 
        ######  don't touch bellow #####
        if context.have_fiat
           buy instrument
           context.number_of_orders    =  context.number_of_orders + 1
           context.price_buy           =  price
           context.commisions_paid     =  context.commisions_paid + context.fee * capital / 100
           context.price_of_last_order =  context.price_buy
           context.last_action_was     =  "buy"
           context.have_coins          =  true
           context.have_fiat           =  false
           context.KrsiZero = false
           context.selltrue = false
           context.buytrue = false
           context.sellcount = 1
    
    if (stoch.D > stoch.K) and (context.prevmacd[2] - macd.macd) < 0.5#context.selltrue and (context.prevmacd[2] - macd.macd) < 0.5 and context.sellcount < 10 and stoch.D > stoch.K     ## you must write here your own condition to sell
        
        ######  don't touch bellow #####
        if context.have_coins 
           sell instrument
           context.number_of_orders    =  context.number_of_orders + 1
           context.price_sell          =  price
           context.commisions_paid     =  context.commisions_paid + context.fee * capital / 100    
           context.price_of_last_order =  context.price_sell   
           context.last_action_was     =  "sell"
           context.have_coins          =  false
           context.have_fiat           =  true
           context.KrsiZero = false
           context.buytrue = false
           context.selltrue = false
           context.sellcount = 1

           #warn "MACD for sell > 0.5: "+(context.prevmacd[2] - macd.macd)
    
    
   

#########################################
######   recalculate capital ############

    fiat     =  portfolio.positions[instrument.curr()].amount
    coins    =  portfolio.positions[instrument.asset()].amount
    capital  =  fiat + coins * price
    
    if context.have_fiat
       efficiency_of_last_trade = -functions.percent(price, context.price_of_last_order)
    else 
       efficiency_of_last_trade = functions.percent(price, context.price_of_last_order) 
   
    percent_buy_and_hold     =  Math.round(100 * functions.percent(price, context.first_price))/100
    percent_bot              =  Math.round(100 * functions.percent(capital, context.first_capital))/100
    efficiency_of_last_trade =  Math.round(100 * efficiency_of_last_trade)/100
    context.commisions_paid  =  Math.round(100 * context.commisions_paid)/100
    context.first_capital    =  Math.round(100 * context.first_capital)/100
    capital   =  Math.round(100 * capital)/100

 
############################################ 
######   debug  stats ######################    

  
    #warn "###########################################################"
    #warn "price now:  #{price}"
    debug "last action was '#{context.last_action_was}' at the price of:  #{context.price_of_last_order}"
    debug "smartness of the bot from the last trade:  #{efficiency_of_last_trade} %"
    debug "total number of buy/sell orders:  #{context.number_of_orders}"
    debug "total commisions paid by now:  #{context.commisions_paid}"
    warn "start capital:  #{context.first_capital}"
    warn "capital now:  #{capital}"
    warn "total buy and hold efficiency:  #{percent_buy_and_hold} %"    
    warn "total bot efficiency:  #{percent_bot} % "
    #warn "MACD Didn't BUY >1: "+(macd.macd - context.prevmacd[2])
    #warn "MACD Didn't SELL >0.5 "+(context.prevmacd[2] - macd.macd)
    #warn "MACD: "+macd.macd
    #warn "MACD Prev: "+context.prevmacd[2]
    #warn "StochK: "+stoch.K
    #warn "StochK Prev:"+context.prev_k[2]
    #warn "StochD: "+stoch.D
    #warn "StochD Prev: "+context.prev_d[2]
    #warn "###########################################################"

   
 
    

    
    
