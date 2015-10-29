#!/usr/bin/env bash

for file in Lab*/prepare.sh; do
    echo -e "\n## Setup running for $(dirname ${file})\n"
    cd $(dirname ${file})
    bash ./prepare.sh
    cd ..
done
