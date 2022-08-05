package main

import (
	"bytes"
	"context"
	"fmt"
	"log"
	"strings"

	"example.com/s3update/types"
	"github.com/gocarina/gocsv"

	"github.com/aws/aws-sdk-go-v2/service/s3"
)

func DownloadWarc(
	ctx context.Context,
	s3Client *s3.Client,
	s3Record types.S3,
) error {
	resp, err := s3Client.GetObject(ctx, &s3.GetObjectInput{
		Bucket: &s3Record.Bucket.Name,
		Key:    &s3Record.Object.Key,
	})
	if err != nil {
		return err
	}

	defer resp.Body.Close()
	var warcs []*types.Warc
	err = gocsv.Unmarshal(resp.Body, &warcs)
	if err != nil {
		return fmt.Errorf("error parsing CSV: %s", err)
	}

	path := strings.Split(s3Record.Object.Key, "/")[1]
	for i, warc := range warcs {
		log.Printf("%d: %+v", i, warc)
		body, err := GetWarc(ctx, s3Client, warc)
		if err != nil {
			return fmt.Errorf("error getting warc: %s", err)
		}

		key := fmt.Sprintf("warc_segment/%s/%d.warc", path, i)
		log.Printf("Uploading %s", key)
		_, err = s3Client.PutObject(
			ctx,
			&s3.PutObjectInput{
				Body:   bytes.NewReader(body),
				Bucket: &s3Record.Bucket.Name,
				Key:    &key,
			},
		)
		if err != nil {
			return fmt.Errorf("error uploading warc: %s", err)
		}
	}

	return nil
}
