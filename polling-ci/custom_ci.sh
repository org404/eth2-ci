GIT_BRANCH=develop

while true; do
    # first time clone
    if [ ! -d "./prysm" ]; then
        git clone --branch "$GIT_BRANCH" --recurse-submodules --depth 1 https://github.com/prysmaticlabs/prysm
    fi
    cd prysm

    # checking for updates
    git fetch
    LOCAL=$(git rev-parse develop);
    REMOTE=$(git rev-parse origin/develop);
    # echo -e \#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\#
    # echo $LOCAL
    # echo ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # echo $REMOTE
    # echo -e \#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # check changes and run CI
    if [ $LOCAL != $REMOTE ]; then
	shortName=$REMOTE:0:10
	echo -e new commit "$shortName" - pulling/running...
        git pull -f develop;
	# passing arguments to the runner:
        ./run_eth2fuzz.sh -f -n commit-$shortName -t 600
    fi

    cd ..
sleep 10
done
