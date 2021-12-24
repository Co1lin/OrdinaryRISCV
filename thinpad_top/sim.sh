export PROJ_NAME='thinpad_top'
export SRC_DIR=$PROJ_NAME'/'$PROJ_NAME'.srcs'

iverilog -g2012 -o wave.out \
	-I $SRC_DIR/sim_1/new \
	-I $SRC_DIR/sim_1/new/include \
	-I $SRC_DIR/sources_1/new/ \
	-I $SRC_DIR/sources_1/new/headers \
	$SRC_DIR/sources_1/new/* \
	$SRC_DIR/sim_1/new/*

vvp -n wave.out
