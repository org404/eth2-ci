
while true; do
    # first time clone
    if [ ! -d "./prysm" ]; then
        git clone --branch "$BRANCH" --recurse-submodules --depth 1 $REPO_URL
    fi

    # checking for updates
    (cd prysm && git fetch)
    LOCAL=$(cd prysm && git rev-parse $BRANCH);
    REMOTE=$(cd prysm && git rev-parse origin/$BRANCH);
    # echo -e \#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\#
    # echo $LOCAL
    # echo ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # echo $REMOTE
    # echo -e \#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # check changes and run CI
    if [ $LOCAL != $REMOTE ]; then
	shortName=$(echo $REMOTE | head -c 10)
	echo -e new commit "$shortName" - pulling/running...
	(cd prysm && git pull -f)
	# passing arguments to the runner:
        ./run_eth2fuzz.sh -f -n fuzzing-$shortName -t 1800
    fi
sleep 10
done
