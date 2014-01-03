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
minmaxprofits v0.1 phomin - email unknown
if thehighesthigh sell(instrument) else if thelowestlow buy(instrument) else debug "Just riding"

class CCB #CryptoCoffeeBot Method v0.1 

    #configurable settings
     minMax = true
    

    #CryptoCoffeeBot Functions 
     @minMax_init: () -> 




NOTE: If you are creating a module replace
all usage of moron with your module name
###          





# Initialization method called before a bot starts. 
# Context object holds script data and will be passed to 'handle' method. 
init: (context)->
     CCB.minMax_init()

#This method does what exactly?  stores persistent variables?
serialize: (context)->
     CCB.minMax_serialize()

# This method is called for each tick
handle: (context, data)->
     CCB.minMax_handle()

# This method is only run at the end of a simulation on cryptotrader.org
finalize: (contex)->
     CCB.minMax_finalize()
    