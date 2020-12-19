nameArg="";
nameCmd="";
forceRebuild=false;
timeArg="";

while getopts "n:ft:" option; do
  case $option in
    n ) nameArg="$OPTARG"
	nameCmd="--name $nameArg"
    ;;
    f ) forceRebuild=true ;;
    t ) timeArg=$OPTARG ;;
  esac
done

echo
if [ -z "$nameArg" ]; then
   echo "Container name is not specified, letting docker decide.";
else
   echo "Using name \"$nameArg\" for container..";
fi
echo
sleep 2

echo
if [ -z $timeArg ]; then
   echo "Running time is not specified, set to default (3600 sec. per test).";
   timeArg=3600;
else
   echo "Running time (per test) is set to $timeArg seconds.";
fi
echo
sleep 2

# @Important: ENV - PATH_TO_ETH2FUZZ=/home/ubuntu/beacon-fuzz/eth2fuzz
PATH2FUZZ=/eth2fuzz
echo using path to fuzzer: "$PATH2FUZZ"
echo
sleep 1
if [ $forceRebuild ]; then
    echo argument for force rebuild was set \(-f\), purging cached image..
    echo
    sleep 2
    (cd $PATH_TO_ETH2FUZZ && make clean-prysm)
    docker builder prune --force --all
    echo
fi

echo starting to build docker image for fuzzing..
echo
sleep 2
# Build prysm image for fuzzing
(cd $PATH2FUZZ && make prysm)
echo
echo running fuzzer
echo
sleep 2
# Fuzz all prysm targets (7) for 1 hour each (3600s)
# docker run -it -v $PATH2FUZZ/workspace:/eth2fuzz/workspace eth2fuzz_prysm continuously -q prysm -t 3600
docker run $nameCmd -d -v $PATH2FUZZ/workspace:/eth2fuzz/workspace eth2fuzz_prysm continuously -q prysm -t $timeArg
