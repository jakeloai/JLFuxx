# JLFuxx

> Designed by **jakelo.ai** · Coded with AI assistance

A web fuzzer that sends HTTP requests with wordlist payloads, then tells you which responses are actually different from the baseline.

---

## What it does

You give it:
- An HTTP request file with `FUZZ` markers
- A wordlist
- A target URL

It sends every payload from the wordlist through the request template, compares each response against a statistical baseline of "normal" responses, and flags the ones that deviate significantly.

That's it. No magic.

---

## Installation

```bash
go install github.com/jakeloai/jlfuxx/cmd/jlfuxx@latest
```

Or build manually:

```bash
git clone https://github.com/jakeloai/JLFuxx.git
cd jlfuxx
go build -ldflags="-s -w" -o jlfuxx ./cmd/jlfuxx
sudo mv jlfuxx /usr/local/bin/
```

---

## How to use

**Basic directory brute:**

```bash
jlfuxx -r request.txt -w wordlist.txt -u http://target.com
```

**Request file format (`request.txt`):**

```
GET /FUZZ HTTP/1.1
Host: target.com
User-Agent: Mozilla/5.0
```

**Multiple wordlists (FUZZ, FUZZ2, FUZZ3):**

```bash
jlfuxx -r req.txt -w dirs.txt -w params.txt -u http://target.com
```

Request file:
```
GET /FUZZ?key=FUZZ2 HTTP/1.1
Host: target.com
```

---

## What the baseline does

Before scanning, it sends ~10 calibration requests with random non-existent paths to learn what a "normal" response looks like for your target. It records:

- Average response size
- Average word count
- Average line count
- Average latency

During the actual scan, any response that deviates significantly from these baselines gets flagged. This catches:
- Pages that exist (different size/content)
- Server errors (different status codes)
- Time delays (blind injection indicators)
- Error signatures in body (stack traces, SQL errors, etc.)

---

## Soft-404 detection

Some sites return 200 OK with a "Not Found" page. The tool learns what a 404 looks like per directory by comparing body content using Jaccard similarity. If a response looks like the known 404 pattern, it gets ignored even if the status code is 200.

Enable it:
```bash
jlfuxx -r req.txt -w dirs.txt -u http://target.com -soft404
```

---

## WAF evasion

Two levels of header manipulation:

- **Level 1**: Random `X-Forwarded-For`, `X-Real-Ip`, and `Accept` headers
- **Level 2**: Adds realistic browser headers (`Sec-Fetch-*`, `DNT`, `Cache-Control`, `X-Request-ID`)

```bash
jlfuxx -r req.txt -w payloads.txt -u http://target.com -evasion 2
```

---

## Recursive scanning

When it finds a directory, it can recurse into it and scan that directory with the same wordlist.

```bash
jlfuxx -r req.txt -w dirs.txt -u http://target.com -recursion -recursion-depth 2
```

---

## Output

It saves results in multiple formats:

```bash
jlfuxx -r req.txt -w wordlist.txt -u http://target.com -of json    # JSON
jlfuxx -r req.txt -w wordlist.txt -u http://target.com -of csv     # CSV
jlfuxx -r req.txt -w wordlist.txt -u http://target.com -of html    # HTML report
jlfuxx -r req.txt -w wordlist.txt -u http://target.com -of md      # Markdown
jlfuxx -r req.txt -w wordlist.txt -u http://target.com -of all     # All formats
```

It also generates:
- `replay/curl/hit_*.sh` — curl scripts to replay any finding
- `responses/` — full response bodies for flagged hits

---

## Rate limiting and delays

```bash
# Max 10 requests per second
jlfuxx -r req.txt -w wordlist.txt -u http://target.com -rate 10

# 0.5 second delay between requests with 50% jitter
jlfuxx -r req.txt -w wordlist.txt -u http://target.com -p 0.5 -jitter 0.5
```

---

## Encoding

Encode payloads before sending:

```bash
# URL encode
jlfuxx -r req.txt -w wordlist.txt -u http://target.com -enc url

# Chain encodings: URL → Base64 → Hex
jlfuxx -r req.txt -w wordlist.txt -u http://target.com -enc url|base64|hex
```

Available: `url`, `doubleurl`, `base64`, `hex`, `html`, `unicode`

---

## Filtering and matching

**Filter out noise:**
```bash
# Hide 404 responses
jlfuxx -r req.txt -w wordlist.txt -u http://target.com -fc 404

# Hide responses of exactly 1234 bytes
jlfuxx -r req.txt -w wordlist.txt -u http://target.com -fs 1234
```

**Only show what matches:**
```bash
# Only show 200 and 302
jlfuxx -r req.txt -w wordlist.txt -u http://target.com -mc 200,302

# Only show responses slower than 1000ms (good for time-based detection)
jlfuxx -r req.txt -w wordlist.txt -u http://target.com -mt 1000
```

**Auto-calibrate filters** based on the baseline:
```bash
jlfuxx -r req.txt -w wordlist.txt -u http://target.com -acc
```

---

## Full option list

```
-u          Target URL
-U          File with multiple targets
-r          HTTP request template file
-w          Wordlist (can use multiple)
-e          Append extensions (e.g., .php, .bak)
-c          Concurrent workers (default: 40)
-timeout    Request timeout in seconds (default: 10)
-p          Delay between requests in seconds
-jitter     Delay randomization ratio (0-1)
-rate       Max requests per second
-retries    Retry failed requests
-x          Proxy URL
-o          Output directory
-of         Output format: json, csv, html, md, all
-sr         Save full response bodies
-sf         Stop on first hit
-se         Stop after N errors
-maxtime    Max total execution time
-recursion  Enable recursive scanning
-recursion-depth  Max recursion depth
-soft404    Enable soft-404 detection
-evasion    WAF evasion level: 0, 1, 2
-enc        Payload encoding
-follow     Follow redirects
-http2      Force HTTP/2
-diff       Enable response diff engine
-cal-rounds Baseline calibration rounds (default: 10)
-threshold  Anomaly score threshold (default: 2.0)
-random-agent  Random User-Agent per request
```

---

## License

MIT © jakelo.ai
