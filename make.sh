#!/bin/bash
export CGO_ENABLED=0

if [[ -n "$1" ]]; then
    LDFLAGS="-X main.Commit=-$(git rev-parse --short HEAD)"
else
    LDFLAGS=""
fi

go mod download

readarray -t goSupported <<< "$(go tool dist list)"

for tuple in "${goSupported[@]}"; do
    readarray -t -d '/' osArch <<< ${tuple}

    GOOS=$(echo ${osArch[0]} | xargs)
    GOARCH=$(echo ${osArch[1]} | xargs)

    mkdir -p build/$GOOS-$GOARCH

    if [[ $GOOS == "windows" ]]; then
        binaryFileName="ytarchive.exe"
    else
        binaryFileName="ytarchive"
    fi

    GOOS=$GOOS GOARCH=$GOARCH go build -o build/$GOOS-$GOARCH/$binaryFileName -ldflags "$LDFLAGS" && \
        7z a -tzip -mx=5 build/ytarchive-$GOOS-$GOARCH.zip ./build/$GOOS-$GOARCH/$binaryFileName &
done

wait

cd ./build
printf "\nChecksums:\n"
sha256sum *.zip | tee SHA256CHKSUMS
