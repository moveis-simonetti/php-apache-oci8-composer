#!/bin/bash

set -e

server-warmup

exec apache2-foreground
