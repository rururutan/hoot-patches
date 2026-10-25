// trtfext reproduces the game's resident-code sector reads from disk A.
package main

import (
	"bytes"
	"fmt"
	"os"
)

func run(args []string) error {
	if len(args) != 1 {
		return fmt.Errorf("usage: trtfext.exe disk_A.2HD")
	}
	image, err := os.ReadFile(args[0])
	if err != nil {
		return err
	}
	if output, statErr := os.Stat("driver.bin"); statErr == nil {
		input, inputErr := os.Stat(args[0])
		if inputErr != nil {
			return inputErr
		}
		if os.SameFile(input, output) {
			return fmt.Errorf("input and output must be different files")
		}
	}
	if len(image) != 1261568 || !bytes.Equal(image[2:29], []byte("Lee Way Corporation By Tino")) {
		return fmt.Errorf("not the supported Tritorn Final disk A image")
	}
	data := make([]byte, 0, 65536)
	// 1024-byte sectors, 8 sectors/head, 2 heads/cylinder.
	// Cylinders 65..72, head 1, sectors 1..8 -> RAM $40000..$4ffff.
	for cylinder := 65; cylinder <= 72; cylinder++ {
		start := (cylinder*2 + 1) * 8192
		data = append(data, image[start:start+8192]...)
	}
	if !bytes.Equal(data[:24], []byte{0x60, 0, 0x0b, 0x34, 0x60, 0, 1, 0x50, 0x60, 0, 1, 0x0c, 0x60, 0, 1, 0x70, 0x60, 0, 6, 0xb0, 0x60, 0, 7, 0x14}) {
		return fmt.Errorf("unexpected resident entry table")
	}
	f, err := os.Create("driver.bin")
	if err != nil {
		return err
	}
	n, writeErr := f.Write(data)
	syncErr := f.Sync()
	closeErr := f.Close()
	if writeErr != nil {
		return writeErr
	}
	if n != len(data) {
		return fmt.Errorf("short output write")
	}
	if syncErr != nil {
		return syncErr
	}
	if closeErr != nil {
		return closeErr
	}
	fmt.Printf("%s: %d bytes (cylinders 65..72, head 1)\n", "driver.bin", len(data))
	return nil
}
func main() {
	if err := run(os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, "trtfext:", err)
		os.Exit(1)
	}
}
