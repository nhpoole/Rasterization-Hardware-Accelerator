#!/bin/bash

if [ $# -ne 1 ]; then
    echo "usage $0 <btor2 file>"
    exit 1
fi

NUM_BAD=`grep -c "[[:space:]]bad[[:space:]]" $1`
echo "Found $NUM_BAD properties to check"
let MAX_PROP_ID=$NUM_BAD-1

failed_props=""

for idx in `seq 0 $MAX_PROP_ID`; do
    let num=idx+1

    # get the name of the property from the btor2 file
    bad_line=$(grep "[[:space:]]bad[[:space:]]" -m $num $1 | tail -n1 | sed "s_./__g")
    bad_line_array=($bad_line)
    prop_name=${bad_line_array[-1]}

    # run on this property
    CMD="pono -e ind -v 1 --reset rst -k 10 --vcd trace_$prop_name.vcd -p $idx $1"
    cat <<EOF


======================================================================================================
Running: $CMD
======================================================================================================
EOF

    eval $CMD
    exit_status=$?

    # save the list of failed properties
    if [ "$exit_status" -eq "0" ]; then
        failed_props="$failed_props \n\t$prop_name"
    fi
done

echo -e "\n\n"
if [[ $failed_props != "" ]]; then
    echo -e "Failed properties: $failed_props"
else
    echo -e "No failed properties. Every property was either proven or could not be violated in 10 steps."
fi

