# S5

Secure Sync to Amazon S3(Simple Storage Service).

## Installation

Add this line to your application's Gemfile:

    gem 's5'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install s5

## Usage

For exapme. ~/project directory sync to 'yalab-project' S3 bucket.

```bash
$ s5 observe ~/project --backet="YOUR_BUCKET_NAME"
```

Files under ~/project directory will client side encryption and put to S3 bucekt. 

You *must backup* the encryption key. It is to create on **~/.s5.key**.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
