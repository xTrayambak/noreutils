proc getPriority*(which, who: cint): cint {.importc: "getpriority", header: "<sys/resource.h>".}
proc setPriority*(which, who, value: cint): cint {.importc: "setpriority", header: "<sys/resource.h>".}
