package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"os"
	"strconv"
	"strings"
)

var deltaPtr = flag.Int("delta", 0, "")

func main() {
	flag.Parse()

	var platforms []struct {
		Versions []struct {
			V8Version string `json:"v8_version"`
		}
	}

	res, err := http.Get("https://omahaproxy.appspot.com/all.json?os=linux&channel=dev")
	if err != nil {
		panic(err)
	}

	defer res.Body.Close()
	defer io.Copy(ioutil.Discard, res.Body)

	if res.StatusCode != 200 {
		panic("unexpcted http status code")
	}

	err = json.NewDecoder(res.Body).Decode(&platforms)
	if err != nil {
		panic(err)
	}

	if len(platforms) != 1 {
		panic("expected one platform")
	}

	if len(platforms[0].Versions) != 1 {
		panic("expected one version")
	}

	version := platforms[0].Versions[0].V8Version
	if version == "" {
		panic("expected a version")
	}

	versionStringParts := strings.Split(version, ".")
	versionParts := make([]int, 0, len(versionStringParts))
	for _, p := range versionStringParts {
		i, err := strconv.Atoi(p)
		if err != nil {
			panic(err)
		}

		versionParts = append(versionParts, i)
	}
	if len(versionParts) > 2 {
		versionParts = versionParts[:2]
	}
	if len(versionParts) != 2 {
		panic("expected two version parts")
	}

	delta := *deltaPtr

	versionParts[1] = versionParts[1] - delta
	for versionParts[1] < 0 {
		versionParts[1] = versionParts[1] + 10
		versionParts[0] = versionParts[0] - 1
	}

	fmt.Fprintf(os.Stderr, "V8_DEV:     %s\n", version)
	fmt.Fprintf(os.Stderr, "V8_VERSION: %d.%d\n", versionParts[0], versionParts[1])
	fmt.Printf("%d.%d\n", versionParts[0], versionParts[1])
}
