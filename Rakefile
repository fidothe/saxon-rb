require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'jars/installer'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

desc "Install JAR dependencies"
task :install_jars do
  Jars::Installer.vendor_jars!
end

desc "Generate travis-esque build matrix config"
task :circleci do
  require 'yaml'
  class CircleCIConfig
    def self.generate(path)
      new.generate(path)
    end

    def generate(path)
      File.open(path, 'w:utf-8') do |f|
        f.write(YAML.dump(config))
      end
    end
    def jruby_image_tags
      %w{9.2.9.0 9.1.17.0 9.2.10.0 9.2.11.1 9.2.12.0 9.2.13.0-SNAPSHOT-latest}
    end

    def jdk_image_tags
      {
        "8-jdk-slim" => "JDK 8",
        "11-jdk-slim" => "JDK 11",
        "13-jdk-slim" => "JDK 13"
      }
    end

    def alt_saxon_urls
      {
        "https://sourceforge.net/projects/saxon/files/Saxon-HE/9.8/SaxonHE9-8-0-15J.zip" => "saxon-he-9.8",
        "https://sourceforge.net/projects/saxon/files/Saxon-HE/10/Java/SaxonHE10-2J.zip" => "saxon-he-10.2"
      }
    end

    def skip_jdk_versions
      [
        %w{9.1.17.0 11-jdk-slim},
        %w{9.1.17.0 13-jdk-slim},
      ]
    end

    def codeclimate_jobs
      (alt_saxon_urls.keys << nil).map { |alt_saxon_url|
        ["9.2.12.0", "8-jdk-slim", alt_saxon_url]
      }
    end

    def all_job_variants
      jruby_image_tags.product(jdk_image_tags.keys, alt_saxon_urls.keys << nil).reject { |jruby, jdk, _|
        skip_jdk_versions.include?([jruby, jdk])
      }
    end

    def job_name(jruby_image_tag, jdk_image_tag, alt_saxon_url)
      [
        "JRuby #{jruby_image_tag}, #{jdk_image_tags[jdk_image_tag]}",
        alt_saxon_urls[alt_saxon_url]
      ].compact.join(' ')
    end

    def all_job_names
      all_job_variants.map { |jruby_image_tag, jdk_image_tag, alt_saxon_url|
        job_name(jruby_image_tag, jdk_image_tag, alt_saxon_url)
      }
    end

    def jobs
      all_job_variants.map { |jruby_image_tag, jdk_image_tag, alt_saxon_url|
        run_codeclimate = codeclimate_jobs.include?([jruby_image_tag, jdk_image_tag, alt_saxon_url])
        [
          job_name(jruby_image_tag, jdk_image_tag, alt_saxon_url),
          job_config({
            run_codeclimate: run_codeclimate, alt_saxon_url: alt_saxon_url,
            docker_image: docker_image(jruby_image_tag, jdk_image_tag)
          })
        ]
      }.to_h.merge(report_test_coverage_job({
        docker_image: "circleci/ruby:latest",
        run_codeclimate: true
      }))
    end

    def docker_image(jruby_image_tag, jdk_image_tag)
      "fidothe/circleci:jruby-#{jruby_image_tag}-#{jdk_image_tag}"
    end

    def job_config(opts = {})
      job = {
        "docker" => [
          {"image" => opts.fetch(:docker_image)}
        ],
        "environment" => environment(opts),
        "steps" => steps(opts)
      }
    end

    def environment(opts = {})
      env = {
        "BUNDLE_JOBS" => 3,
        "BUNDLE_RETRY" => 3,
        "BUNDLE_PATH" => "vendor/bundle",
        "JRUBY_OPTS" => "--dev --debug"
      }
      env["ALTERNATE_SAXON_HOME"] = "/tmp/saxon" if opts.fetch(:alt_saxon_url)
      env
    end

    def steps(opts = {})
      [
        "checkout",
        alt_saxon_install(opts),
        {
          "run" => {
            "name" => "Bundle Install",
            "command" => "bundle check || bundle install"
          }
        },
        install_codeclimate_reporter_step(opts),
        run_tests_step(opts),
        persist_test_coverage_to_workspace_step(opts),
        {
          "store_test_results" => {"path" => "/tmp/test-results"}
        },
        {
          "store_artifacts" => {"path" => "/tmp/test-results", "destination" => "test-results"}
        }
      ].compact
    end

    def alt_saxon_install(opts)
      return nil unless opts.fetch(:alt_saxon_url)
      saxon_file = File.basename(opts[:alt_saxon_url])
      {
        "run" => {
          "name" => "Download #{saxon_file}",
          "command" => [
            "mkdir -p /tmp/saxon",
            "cd /tmp/saxon",
            "curl -L -O #{opts[:alt_saxon_url]}",
            "unzip #{saxon_file}",
            "rm -f #{saxon_file}"
          ].join("\n")
        }
      }
    end

    def attach_workspace_step(opts)
      return nil unless opts.fetch(:run_codeclimate)
      {
        "attach_workspace" => {
          "at" => "/tmp/workspace"
        }
      }
    end

    def install_codeclimate_reporter_step(opts)
      return nil unless opts.fetch(:run_codeclimate)
      {
        "run" => {
          "name" => "Install Code Climate Test Reporter",
          "command" =>
          "curl -L https://codeclimate.com/downloads/test-reporter/test-reporter-latest-linux-amd64 > ./cc-test-reporter\n" +
          "chmod +x ./cc-test-reporter\n"
        }
      }
    end

    def persist_test_coverage_to_workspace_step(opts)
      return nil unless opts.fetch(:run_codeclimate)
      {
        "persist_to_workspace" => {
          "root" => "~/project",
          "paths" => [
            "cc-coverage*"
          ]
        }
      }
    end

    def run_tests_step(opts)
      command = [
        "mkdir -p /tmp/test-results",
        "VERIFY_SAXON_LAZY_LOADING=1 bundle exec rspec spec/jar_loading_spec.rb --options .rspec-jar-loading --profile 10 --format RspecJunitFormatter --out /tmp/test-results/rspec-jar-loading.xml"
      ]
      cc_suffix = opts.fetch(:alt_saxon_url) ? "-alt-#{alt_saxon_urls[opts.fetch(:alt_saxon_url)]}" : ''
      if opts.fetch(:run_codeclimate)
        command.prepend("./cc-test-reporter before-build")
        command.append("if [ $? -eq 0 ]; then ./cc-test-reporter format-coverage -t simplecov -o \"cc-coverage-jar-loading#{cc_suffix}.json\"; fi")
      end
      command.append("rm -rf coverage")
      command.append("bundle exec rspec spec --profile 10 --format RspecJunitFormatter --out /tmp/test-results/rspec.xml --format progress")
      if opts.fetch(:run_codeclimate)
        command.append("if [ $? -eq 0 ]; then ./cc-test-reporter format-coverage -t simplecov -o \"cc-coverage-main#{cc_suffix}.json\"; fi")
      end

      {
        "run" => {
          "name" => "Run the tests" + (opts.fetch(:run_codeclimate) ? ", and upload coverage data to Code Climate" : ""),
          "command" => command.join("\n")
        }
      }
    end

    def report_test_coverage_job(opts)
      {
        "Report test coverage to Code Climate" => {
          "docker" => [
            {"image" => opts.fetch(:docker_image)}
          ],
          "steps" => [
            {
              "attach_workspace" => {
                "at" => "/tmp/workspace"
              }
            },
            install_codeclimate_reporter_step(opts),
            {
              "run" => {
                "name" => "Upload test coverage to Code Climate",
                "command" => "find /tmp/workspace -name 'cc-coverage*.json' &&\\\n ./cc-test-reporter sum-coverage /tmp/workspace/cc-coverage*.json &&\\\n ./cc-test-reporter upload-coverage"
              }
            }
          ]
        }
      }
    end

    def config
      {
        "version" => 2,
        "jobs" => jobs,
        "workflows" => {
          "version" => 2,
          "build_and_test" => {
            "jobs" => all_job_names << {
              "Report test coverage to Code Climate" => {
                "requires" => codeclimate_jobs.map { |args| job_name(*args) }
              }
            }
          }
        }
      }
    end
  end

  CircleCIConfig.generate('.circleci/config.yml')
end
