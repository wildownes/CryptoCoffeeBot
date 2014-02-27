###
YOUR BOT NAME v0.1 - username / email
    BTC xxxxxxxxxxxxxxxxxxx
In this state the bot does no trades
but provides a base framework to begin a
new algorithm that includes: 

****Module Credits**** (PLEASE KEEP UPDATED)
OpenSettings module v0.1 by wild0wnes
    BTC 1FCmfke28oSjJA7VCMLFnoCxqSQaGRaW7b

SimplePlot module v1 by wild0wnes
    BTC 1FCmfke28oSjJA7VCMLFnoCxqSQaGRaW7b

Stats & Orders module v0.4.6 by sportpilot
    BTC 1561k5XqWFJSHP8apmvGt15ecWjw9ZLKGi
###

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# OpenSettings - v0.1 by wild0wnes
# BTC - 1FCmfke28oSjJA7VCMLFnoCxqSQaGRaW7b
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
class OpenSettings
  @module_disabler: (context, data)->
    context.OS_module1 = true #SimplePlot True/False
    context.OS_module2 = true #Stats True/False

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# SimplePlot module v1 by wild0wnes
# BTC - 1FCmfke28oSjJA7VCMLFnoCxqSQaGRaW7b
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
class SimplePlot
  @handle: (context, data)->
    instrument = data.instruments[0]
    Close = instrument.close[instrument.close.length - 1]
    High = instrument.high[instrument.high.length - 1]
    Low = instrument.low[instrument.low.length - 1]
    plot
      Close: Close
      High: High
      Low: Low

#>>>>>>>>>>>>>>>>>>>>>> END MODULES >>>>>>>>>>>>>>>>>>>>

#>>>>>>>>>>>>>>>>>>>>>> START ALGORITM >>>>>>>>>>>>>>>>>>>>

# HERE IS A PLACE TO PUT ALGORITM CODE

#>>>>>>>>>>>>>>>>>>>>>> END ALGORITM >>>>>>>>>>>>>>>>>>>>

#>>>>>>>>>>>>>>>>>>>>>> BEGIN CORE METHODS >>>>>>>>>>>>>>>>>>>>
# Initialization method called before a bot starts.
init: (context)->
  OpenSettings.module_disabler(context)
  Stats.context(context)unless context.OS_module2 == false

#This method allows variables to persist after a restart
serialize: (context)->
  Stats.serialize(context)unless context.OS_module2 == false

# This method is called for each tick
handle: (context, data)->
  instrument = data.instruments[0]
  Stats.handle(context, data)unless context.OS_module2 == false
  SimplePlot.handle(context, data) unless context.OS_module1 == false

# This method is only run at the end of a simulation on cryptotrader.org
finalize: (context)->
  Stats.finalize(context)unless context.OS_module2 == false
