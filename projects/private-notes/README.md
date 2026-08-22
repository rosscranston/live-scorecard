# Private Notes

Private Call Notepad stores one timestamped Markdown document per day in
`notes/`. While the app is open, it commits and pushes changes every 30 minutes.

Each note line starts with the local time at which typing began:

```text
[09:30:12] Example note
```

After more than 10 seconds without typing, the next text begins a new
timestamped line.
