#!/usr/bin/env bash
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Lists every test Surefire skipped, with the skip reason from its report and the
# assume*/@Disabled source lines that caused it (some assumptions carry no message,
# so the report alone reads "assumption is not true").
set -u
echo "Skipped tests and their reasons:"
for xml in target/surefire-reports/TEST-*.xml; do
  [ -f "$xml" ] || continue
  awk '
    /<testcase / {
      match($0, /name="[^"]*"/); n = substr($0, RSTART + 6, RLENGTH - 7)
      match($0, /classname="[^"]*"/); c = substr($0, RSTART + 11, RLENGTH - 12)
    }
    /<skipped/ {
      msg = "(no message)"
      if (match($0, /message="[^"]*"/)) msg = substr($0, RSTART + 9, RLENGTH - 10)
      print c "\t" n "\t" msg
    }' "$xml"
done | while IFS="$(printf '\t')" read -r cls name msg; do
  echo "SKIPPED ${cls}.${name}: ${msg}"
  src="src/test/java/$(echo "${cls}" | tr . /).java"
  meth="${name%%(*}"
  if [ -f "$src" ]; then
    awk -v m="$meth" '
      $0 ~ ("void " m "\\(") { p = 1; for (i = 1; i <= nb; i++) print "    " FILENAME ":" bl[i] ": " bt[i] }
      !p && /^[[:space:]]*@/ { nb++; bl[nb] = FNR; bt[nb] = $0; next }
      !p && !/^[[:space:]]*$/ { nb = 0 }
      p && /assume|Assume/ { print "    " FILENAME ":" FNR ": " $0 }
      p && /^    }/ { exit }' "$src"
  fi
done
