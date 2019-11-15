# Replicated Docker Image for Statsd + Carbon + Graphite

Originally based off of: https://github.com/CastawayLabs/graphite-statsd

To deploy a new image, push a tag in the format `/^[0-9]+(\.[0-9]+)*(-.*)*/`.

```
git tag -a 1.0.5 -m "Release 1.0.5" && git push origin 1.0.5
```
