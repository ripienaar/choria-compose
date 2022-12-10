package main

import (
	"encoding/json"
	"log"
	"os"
	"os/user"

	"github.com/AstroProfundis/sysinfo"
)

func main() {
	current, err := user.Current()
	if err != nil {
		log.Fatal(err)
	}

	if current.Uid != "0" {
		log.Fatal("requires superuser privilege")
	}

	var si sysinfo.SysInfo

	si.GetSysInfo()

	tf, err := os.CreateTemp("/etc/choria", "facts.*")
	if err != nil {
		log.Fatal(err)
	}
	defer os.Remove(tf.Name())

	data, err := json.MarshalIndent(&si, "", "  ")
	if err != nil {
		log.Fatal(err)
	}

	_, err = tf.Write(data)
	if err != nil {
		log.Fatal(err)
	}

	tf.Close()
	os.Rename(tf.Name(), "/etc/choria/facts.json")
}
