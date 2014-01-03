###
SKELETON BOT v0.1 - wild0wnes
    BTC 1FCmfke28oSjJA7VCMLFnoCxqSQaGRaW7b
    LTC LVABNAWia83o6EcM8L17kf7s3X7uqTyUuf

In this state the bot does no trades
but provides a simple framework to begin a
new algorithm. To use this code you will need
to use either github.com/pulsecat/cryptrade 
or cryptotrader.org

****Module Credits**** (PLEASE KEEP UPDATED)
pTick v0.1 wild0wnes - wildownes@inbox.com
    BTC 1FCmfke28oSjJA7VCMLFnoCxqSQaGRaW7b
    LTC LVABNAWia83o6EcM8L17kf7s3X7uqTyUuf

NOTE: If you are creating a module replace
all usage of pTick with your module name
###          

class CCB #CryptoCoffeeBot Method v0.1 

    #configurable settings
     pTick = true
    

    #CryptoCoffeeBot Functions 
     @pTick_init: () -> 
         if pTick == true
             debug "initializing..."
             context.pTick = 0 #	
     @pTick_handle: () ->
         if pTick == true
             debug "pTick  " + (context.pTick += 1)
     @pTick_serialize: () ->
         if pTick == true
             pTick:context.pTick
     @pTick_finalize: () ->
         if pTick == true
             debug "finalize...."
             info "Total Processed Ticks " + context.pTick




# Initialization method called before a bot starts. 
# Context object holds script data and will be passed to 'handle' method. 
init: (context)->
     CCB.pTick_init()

#This method does what exactly?  stores persistent variables?
serialize: (context)->
     CCB.pTick_serialize()

# This method is called for each tick
handle: (context, data)->
     CCB.pTick_handle()

# This method is only run at the end of a simulation on cryptotrader.org
finalize: (contex)->
     CCB.pTick_finalize()
    