import sys

def generate(N):
    for a in range(N):
        for b in range(a+1, N):
            for c in range(b+1, N):
                yield (a, b, c)

for i, t in enumerate(generate(30)):
    print i, t
