```
export API_KEY=

```


```

{
  "config": {
    "encoding": "LINEAR16",
    "languageCode": "en-US",
    "audioChannelCount": 2
  },
  "audio": {
    "uri": "gs://spls/arc131/question_en.wav"
  }
}

```



**Edit command according to your lab**
```
curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json \
"https://speech.googleapis.com/v1/speech:recognize?key=$API_KEY" > speech_response.json
```



```
{
  "config": {
    "encoding": "FLAC",
    "languageCode": "es-ES"
  },
  "audio": {
    "uri": "gs://spls/arc131/multi_es.flac"
  }
}

```

```
curl -s -X POST -H "Content-Type: application/json" --data-binary @speech_request_sp.json \
"https://speech.googleapis.com/v1/speech:recognize?key=$API_KEY" > response_speech_sp.json

```
