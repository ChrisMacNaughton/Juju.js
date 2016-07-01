scope = if typeof window == 'undefined' then global else window
# shim process
scope.process = env: NODE_ENV: 'development'
# require all test files
testsContext = require.context('.', true, /_spec$/)

testsContext.keys().forEach testsContext
