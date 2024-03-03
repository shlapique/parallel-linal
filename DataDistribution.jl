module DataDistribution
using ParallelDataTransfer

export mailing

# sends init data for every proc
function mailing(nprc, A, ranges)
    for r in range(1, nprc)
        varA = view(A, ranges[r], :)
        sendto(w[r], vA=varA)
    end
end

end
