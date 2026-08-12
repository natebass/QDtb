function compare_bucket
    set bucket_path "gs://ca-panel-001-resources/resources"
    set local_path "./resources"

    echo "--- Fetching remote structure ---"
    # List remote, remove the bucket prefix, remove trailing slashes, sort
    gsutil ls -r $bucket_path/\*\* | string replace $bucket_path/ "" | string trim -c / | sort > remote_files.txt

    echo "--- Scanning local structure ---"
    # Find local files, remove leading './resources/', sort
    find $local_path -mindepth 1 | string replace "$local_path/" "" | string trim -c / | sort > local_files.txt

    echo "--- Comparison Result ( < Remote | > Local ) ---"
    diff remote_files.txt local_files.txt

    # Cleanup
#    rm remote_files.txt local_files.txt
end

