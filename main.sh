import base
import common
import "kind/$HOST_KIND"
import "host/$HOST_NAME"

write /var/lib/syscfg/rev "$(git rev-parse @)"
