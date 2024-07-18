#!/bin/bash
instances=$(find . | grep -v templates | grep yaml | grep -v Chart)
for inst in $instances; do
  rm $inst
done
