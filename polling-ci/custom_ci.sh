declare -a CURRENTLY_RUNNING;
BF_V2_TESTS=("attestation" "attesterslashing" "block" "blockheader" "deposit" "proposerslashing" "voluntaryexit")
BF_V2=/bf_v2;

remove_item () {
    for (( i=0; i<${#CURRENTLY_RUNNING[@]}; i++ )); do 
    	if [[ ${CURRENTLY_RUNNING[i]} == $1 ]]; then
            CURRENTLY_RUNNING=( "${CURRENTLY_RUNNING[@]:0:$i}" "${CURRENTLY_RUNNING[@]:$((i + 1))}" );
            i=$((i - 1));
        fi
    done
}

bfv2_name () {
    # first param is a commit id
    commit=$1;
    # second param is a test name for beaconfuzz_v2
    test_name=$2;

    return "bfuzz-v2-$commit-$test_name";
}

build_bfv2 () {
    echo -e building beaconfuzz_v2 for $1
    # TODO
}

run_bfv2 () {
    # build beaconfuzz_v2
    build_bfv2

    # first param is a commit id
    commit=$1;
    # seconds param is number of seconds to run tests for
    run_for=$2;

    # list of containers
    declare -a containers;
    # deploy all tests
    for test_name in $BF_V2_TESTS; do
	cont_name=(bfv2_name $commit $test_name);
	# deploy container for each test
	docker run --cpus=0.35 --name $cont_name -d -v $PATH_TO_FUZZER/eth2fuzz/workspace:/eth2fuzz/workspace -v $PATH_TO_FUZZER/eth2fuzz/workspace/corpora:/corpora beaconfuzz_v2 fuzz $test_name -f /corpora;

	containers+=($cont_name);
    done

    CURRENTLY_RUNNING+=containers;
    
    # wait until tests run
    sleep $run_for;

    # stop containers afterwise
    stop_if_exist $containers;
}

stop_if_exist () {
    # first param is a list of containers to stop
    containers=$1;

    # if container was already removed this loop will just skip,
    # both commands here are not strict
    for cont_name in $containers; do
        ./stop.sh $cont_name;
        remove_item $cont_name;
    done
}

while true; do
    # first time clone
    if [ ! -d "./prysm" ]; then
        git clone --branch "$BRANCH" --recurse-submodules --depth 1 $REPO_URL
	echo -e looking for updates...
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
	oldName=$(echo $LOCAL | head -c 10)
	echo -e discovered new commit
	echo -e killing outdated running containers for $oldName...
	stop_if_exist $CURRENTLY_RUNNING

	shortName=$(echo $REMOTE | head -c 10)
	echo -e pulling "$shortName"...
	(cd prysm && git pull -f)

	echo -e running eth2fuzz for "$shortName"...
	eth2fuzz_name="eth2fuzz-$shortName"
	# passing arguments to the runner:
	#    "-t" is amount of time (in seconds) to run for
	#    "-n" name for the container
	#    "-f" ensure it is rebuild
        ./run_eth2fuzz.sh -f -n $eth2fuzz_name -t 1800
	CURRENTLY_RUNNING+=($eth2fuzz_name)
	
	# TODO
	# echo -e running beaconfuzz_v2
	# run_bfv2

	# adding empty line in the end
	echo
    fi
sleep 10
done
