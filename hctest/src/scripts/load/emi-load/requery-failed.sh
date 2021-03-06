#
# $Id$
#
# Copyright � 2008, Sun Microsystems, Inc.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#   # Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#
#   # Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
#
#   # Neither the name of Sun Microsystems, Inc. nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
# IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
# OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.



#

# find and source ENV file
DIR=`dirname $0`
ENV=$DIR/ENV
if [ ! -f $ENV ]; then
    echo "ERROR: can't find ENV file $ENV" 1>&2
    exit 1
fi
. $ENV

let tries=10
let currentTry=1
let qryThreads=10
infile=${LOGDIR}/initial-failed-qry.out

egrep -h 'QRY ERR' ${LOGDIR}/query-each-repeat.*.out  | sort -k 3 -u > ${infile}

while [ $currentTry -le $tries ]; do
        if  ! test -s ${infile}; then
                break
        fi
        outfile="${LOGDIR}/re-qry.${currentTry}.out"
        errFile="${LOGDIR}/re-qry.${currentTry}.err"
        echo "re-query failed queries. Attempt # $currentTry"
        echo "output file $outfile , error file $errFile" 

	# In the step below we need to transform 'QRY ERR' to
	# 'QRY OK' otherwise the entry will be ignored by EMI
        cat $infile |  sed -e 's|QRY ERR|QRY OK|g' | java -classpath \
        $CLASSPATH com.sun.honeycomb.test.stress.QueryStress \
        $DATAVIP $qryThreads -1 -1 - > ${outfile} 2>${errFile}

        infile=`mktemp`
        egrep 'QRY ERR' ${outfile} > ${infile}
        echo "attempt # $currentTry completed."
        let currentTry=$((currentTry + 1 ))
done

if [ -a $infile ]; then
	cp ${infile} ${LOGDIR}/final-failed-qry.out
fi

if [ -n "${errFile}" ] && [ -a ${errFile} ]; then 
	cp ${errFile} ${LOGDIR}/final-failed-qry.err
fi
