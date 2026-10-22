import common
import "kind/$HOST_KIND"
import "host/$HOST_NAME"

run bash -eu /usr/local/lib/syscfg/upgrade.sh
