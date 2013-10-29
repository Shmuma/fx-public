import sys

def generate(N):
    for a in range(N):
        for b in range(a+1, N):
            for c in range(b+1, N):
                yield (a, b, c)


def triple_index(N, t):
    a, b, c = t
    res = 0
    for i in range(a-1):
        res += (N-i-1)*(N-i-2)
    return res


def do_test(N):   
    forward = {}
    backward = {}
    for i, t in enumerate(generate(N)):
        forward[i] = t
        backward[t] = i

    # forward map
#    for i in forward.keys():
#        print i, forward[i]

    # backward map
    for t in backward.keys():
        print t,"\t", backward[t], "\t", triple_index(N, t)


if __name__ == "__main__":
    do_test(30)
