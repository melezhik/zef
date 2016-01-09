use Zef;
use Zef::Shell;

class Zef::Shell::Test is Zef::Shell does Tester does Messenger {
    method test-matcher($path) { so self.find-tests($path).elems }

    method probe { $ = True }

    method test($path) {
        die "path does not exist: {$path}" unless $path.IO.e;
        my @test-files = self.find-tests($path);

        my @results = gather for @test-files -> $test-file {
            # many tests are written with the assumption that $*CWD will be their distro's base directory
            # so we have to hack around it so people can still (rightfully) pass absolute paths to `.test`
            my $rel-test  = $test-file.relative($path);
            say "[DEBUG] Testing: {$rel-test}";
            my $proc = zrun($*EXECUTABLE, '-Ilib', $rel-test, :cwd($path), :out, :err);
            .say for $proc.out.lines;
            .say for $proc.err.lines;
            $proc.out.close;
            $proc.err.close;
            take $proc;
        }
        ?@results.map(?*);
    }

    method find-tests($path) {
        my @stack = $path.IO.child('t').absolute;
        my $perl-files := gather while ( @stack ) {
            my $current = @stack.pop;
            take $current.IO if ($current.IO.f && $current.IO.extension ~~ rx:i/t$/);
            @stack.append(dir($current)>>.path) if $current.IO.d;
        }
    }
}
