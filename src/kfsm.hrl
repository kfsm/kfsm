

-define(VERBOSE, true).
-ifdef(VERBOSE).
   -define(DEBUG(Str, Args), error_logger:info_msg(Str, Args)).
-else.
   -define(DEBUG(Str, Args), ok).
-endif.

%% default timeout for synchronous messaging
-define(DEF_TIMEOUT, 5000).