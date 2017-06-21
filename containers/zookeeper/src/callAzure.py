#!/usr/bin/env python

import sys
import os
import json
import ast
import time
import subprocess

res = subprocess.check_output(["azure", "telemetry", "--disable"])
print(res)



