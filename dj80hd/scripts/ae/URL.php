<?php
// $Id: URL.php,v 1.6 2003/07/15 23:38:15 k1m Exp $
// +----------------------------------------------------------------------+
// | URL Class 0.3                                                        |
// +----------------------------------------------------------------------+
// | Author: Keyvan Minoukadeh - keyvan@k1m.com - http://www.keyvan.net   |
// +----------------------------------------------------------------------+
// | PHP class for handling URLs                                          |
// +----------------------------------------------------------------------+
// | This program is free software; you can redistribute it and/or        |
// | modify it under the terms of the GNU General Public License          |
// | as published by the Free Software Foundation; either version 2       |
// | of the License, or (at your option) any later version.               |
// |                                                                      |
// | This program is distributed in the hope that it will be useful,      |
// | but WITHOUT ANY WARRANTY; without even the implied warranty of       |
// | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the        |
// | GNU General Public License for more details.                         |
// +----------------------------------------------------------------------+

define('URL_OPTION_NO_FRAG', 0);
define('URL_OPTION_WITH_FRAG', 1);

/**
* URL class intended for http and https schemes
*
* This class allows you store absolute or relative URLs and access it's
* various parts (scheme, host, port, part, query, fragment).
*
* It will also accept and attempt to resolve a relative URL against an
* absolute URL already stored.
*
* Note: this URL class is based on the HTTP scheme.
*
* Example:
* <code>
*   $url =& new URL('http://www.domain.com/path/file.php?query=blah');
*   echo $url->get_scheme(),"\n";    // http
*   echo $url->get_host(),"\n";      // www.domain.com
*   echo $url->get_path(),"\n";      // /path/file.php
*   echo $url->get_query(),"\n";     // query=blah
*   // Setting a relative URL against our existing URL
*   $url->set_relative('../great.php');
*   echo $url->as_string(); // http://www.domain.com/great.php
* </code>
*
* See test_URL.php file for examples of how relative URLs are handled.
*
* CHANGES: 
*  + 0.3 (15-Jul-2003)
*    - equal_to() method added.
*  + 0.2 (30-Dec-2002)
*    - Class name changed from Url to URL.
*    - Added $use_default param to the get_port() method.
*    - Added as_string() method, which is what I should've had instead of get()
*    - Added parameter to as_string() method: $include_fragment (default: true), 
*      passing false to as_string() will omit the fragment and crosshatch ('#')
*      from the URL
*  + 0.1
*    - Initial release
*                      
* TODO:
*  - modify set_relative() to accept URL objects as well as strings
*
* @author Keyvan Minoukadeh <keyvan@k1m.com>
* @version 0.3
*/
class URL
{
    /**
    * Scheme
    * @var string
    * @access private
    */
    var $scheme;

    /**
    * User
    * @var string
    * @access private
    */
    var $user;

    /**
    * Password
    * @var string
    * @access private
    */
    var $pass;

    /**
    * Host
    * @var string
    * @access private
    */
    var $host;

    /**
    * Port
    * @var int
    * @access private
    */
    var $port;

    /**
    * Path
    * @var string
    * @access private
    */
    var $path;

    /**
    * Query
    * @var string
    * @access private
    */
    var $query;

    /**
    * Fragment
    * @var string
    * @access private
    */
    var $fragment;

    /**
    * URL cache
    * @var string
    * @access private
    */
    var $cache;


    /**
    * Constructor
    *
    * Optional parameter accepts a URL string
    * @param string $url
    */
    function URL($url=null)
    {
        if (isset($url)) {
            $this->set($url);
        }
    }

    /**
    * Set URL
    *
    * Will overwrite all existing URL parts (see set_relative() to set a relative URL)
    * @param string $url
    * @return void
    * @see set_relative()
    */
    function set($url)
    {
        $this->cache = null;
        $url = $this->_encode(trim($url));
        $parts = $this->_parse_url($url);
        $this->_set_parts($parts);
    }

    /**
    * Equal to
    *
    * Returns true if <var>$url</var> is equal to current URL object.
    * I'm hoping this method reflects RFC 2616 Section 3.2.3
    *
    * Note: this method will not compare the following:
    *  - user info (username and password)
    *  - fragment (#fragment)
    * @param mixed $url string URL or instance of URL class
    * @return bool
    */
    function equal_to($url)
    {
        if (!is_object($url)) $url =& new URL($url);
        // Check if URL types match:
        // both must be absolute or relative
        if ($this->is_absolute() != $url->is_absolute()) {
            return false;
        }
        // Check port:
        // both ports must be identical, and (from RFC 2616):
        //   - A port that is empty or not given is equivalent to the default
        //     port for that URI-reference.
        // passing true to get_port() will result in the default port for 
        // HTTP and HTTPS schemes to be returned.
        if ($this->get_port(true) != $url->get_port(true)) {
            return false;
        }
        // Check host:
        //   - Comparisons of host names MUST be case-insensitive
        if (strcasecmp($this->get_host(), $url->get_host()) !== 0) {
            return false;
        }
        // Check scheme:
        //   - Comparisons of scheme names MUST be case-insensitive
        if (strcasecmp($this->get_scheme(), $url->get_scheme()) !== 0) {
            return false;
        }
        // Check path:
        //   - An empty abs_path is equivalent to an abs_path of "/".
        $this_tmp = urldecode($this->get_path());
        $url_tmp = urldecode($url->get_path());
        if ($this_tmp == '') $this_tmp = '/';
        if ($url_tmp == '') $url_tmp = '/';
        if (strcmp($this_tmp, $url_tmp) !== 0) {
            return false;
        }
        // Check query
        $this_tmp = urldecode($this->get_query());
        $url_tmp = urldecode($url->get_query());
        if (strcmp($this_tmp, $url_tmp) !== 0) {
            return false;
        }
        // If we've got this far, URLs match
        return true;
    }

    /**
    * Set relative URL
    *
    * Sets a URL as relative to the current URL (base).
    * An absolute URL passed to this method will overwrite all existing URL parts stored.
    * I'm hoping this method reflects RFC 2396 Section 5.2
    * @param string $url
    * @return void
    */
    function set_relative($url)
    {
        $this->cache = null;
        $url = $this->_encode(trim($url));
        $parts = $this->_parse_url($url);
        $this->fragment = (isset($parts['fragment']) ? $parts['fragment'] : null);
        // if path is empty, and scheme, host, and query are undefined,
        // the URL is referring the base URL
        if (($parts['path'] == '') && !isset($parts['scheme']) && !isset($parts['host']) && !isset($parts['query'])) {
            return;
        }
        // if scheme is set URL is absolute
        if (isset($parts['scheme'])) {
            $this->_set_parts($parts);
            return;
        }
        $this->query = (isset($parts['query']) ? $parts['query'] : null);
        if (isset($parts['host'])) {
            $this->host = $parts['host'];
            $this->path = $parts['path'];
            return;
        }
        // start ugly fix:
        // prepend slash to path if base host is set, base path is not set, and url path is not absolute
        if (isset($this->host) && ($this->path == '') && strlen($parts['path'])
                && (substr($parts['path'], 0, 1) != '/')) {
            $parts['path'] = '/'.$parts['path'];
        } // end ugly fix
        if (substr($parts['path'], 0, 1) == '/') {
            $this->path = $parts['path'];
            return;
        }
        // copy base path excluding any characters after the last (right-most) slash character
        $buffer = substr($this->path, 0, (int)strrpos($this->path, '/')+1);
        // append relative path
        $buffer .= $parts['path'];
        // remove "./" where "." is a complete path segment.
        $buffer = str_replace('/./', '/', $buffer);
        if (substr($buffer, 0, 2) == './') {
            $buffer = substr($buffer, 2);
        }
        // if buffer ends with "." as a complete path segment, remove it
        if (substr($buffer, -2) == '/.') {
            $buffer = substr($buffer, 0, -1);
        }
        // remove "<segment>/../" where <segment> is a complete path segment not equal to ".."
        $search_finished = false;
        $segment = explode('/', $buffer);
        while (!$search_finished) {
            for ($x=0; $x+1 < count($segment);) {
                if (($segment[$x] != '') && ($segment[$x] != '..') && ($segment[$x+1] == '..')) {
                    if ($x+2 == count($segment)) $segment[] = '';
                    unset($segment[$x], $segment[$x+1]);
                    $segment = array_values($segment);
                    continue 2;
                } else {
                    $x++;
                }
            }
            $search_finished = true;
        }
        $buffer = (count($segment) == 1) ? '/' : implode('/', $segment);
        $this->path = $buffer;    
    }

    /**
    * Get URL
    *
    * Returns the full URL (excluding any user info).
    * @return string
    * @deprecated deprecated since version 0.2, use as_string() method instead.
    * @see as_string()
    */
    function get()
    {
        return $this->as_string();
    }

    /**
    * As string
    *
    * Returns the full URL (excluding any user info).
    * Optional parameter allows you to specify whether you want the fragment (if available)
    * to be included (default behaviour) in the resulting URL, or omitted.
    * Passing false to as_string() will omit the fragment and crosshatch ('#') from the returned
    * result.
    * @param int $option URL_OPTION_WITH_FRAG (default) or URL_OPTION_NO_FRAG
    * @return string
    * @since 0.2
    */
    function as_string($fragment=URL_OPTION_WITH_FRAG)
    {
        if (isset($this->cache)) {
            $url = $this->cache;
        } else {
            $url = '';
            if (isset($this->scheme)) {
                $url .= $this->scheme.':';
            }
            if (isset($this->host)) {
                $url .= '//'.$this->host;
                if (isset($this->port)) {
                    $url .= ':'.$this->port;
                }
            }
            $url .= $this->path;
            if (isset($this->query)) {
                $url .= '?'.$this->query;
            }
            if (isset($this->fragment)) {
                $url .= '#'.$this->fragment;
            }
            $this->cache = $url;
        }
        if (($fragment == URL_OPTION_WITH_FRAG) || !isset($this->fragment)) {
            return $url;
        }
        return (substr($url, 0, strpos($url, '#')));
    }

    /**
    * Is absolute URL
    *
    * Returns true if scheme was specified
    * @return bool
    * @see is_relative()
    */
    function is_absolute()
    {
        return (isset($this->scheme));
    }

    /**
    * Is relative URL
    *
    * Opposite of is_absolute()
    * @return bool
    * @see is_absolute()
    */
    function is_relative()
    {
        return (!$this->is_absolute());
    }

    /**
    * Get scheme
    *
    * Returns the scheme, or false if no scheme was specified.
    * @return string
    */
    function get_scheme()
    {
        return (isset($this->scheme)) ? $this->scheme : false;
    }

    /**
    * Get username
    *
    * Returns the username, or false if no username was specified.
    * @return string
    */
    function get_user()
    {
        return (isset($this->user)) ? $this->user : false;
    }

    /**
    * Get password
    *
    * Returns the password, or false if no password was specified.
    * @return string
    */
    function get_pass()
    {
        return (isset($this->pass)) ? $this->pass : false;
    }

    /**
    * Get host
    *
    * Returns the hostname/ip, or false if no hostname/ip was specified
    * @return string
    */
    function get_host()
    {
        return (isset($this->host)) ? $this->host : false;
    }

    /**
    * Get port
    *
    * Returns the port number, or false if no port was specified.
    *
    * If you pass true to get_port(), a default port will be returned if no
    * port is found.  This is based on checking if the URL is using the HTTP
    * scheme (if so, 80 will be returned), or HTTPS scheme (if so, 443 will be
    * returned).
    * @param bool $use_default (optional) default: false
    * @return int
    */
    function get_port($use_default=false)
    {
        $port = (isset($this->port)) ? $this->port : false;
        if ($use_default && ($port === false)) {
            if ($this->scheme == 'http') {
                $port = 80;
            } elseif ($this->scheme == 'https') {
                $port = 443;
            }
        }
        return $port;           
    }

    /**
    * Get path
    * @return string
    */
    function get_path()
    {
        return $this->path;
    }

    /**
    * Get query
    *
    * Returns everything after the "?", or false if no query was specified
    * @return string
    */
    function get_query()
    {
        return (isset($this->query)) ? $this->query : false;
    }

    /**
    * Get path and query
    *
    * Returns the path and (if available) the query
    * @return string
    * @since 0.2
    */
    function get_path_query()
    {
        return $this->path.(isset($this->query) ? '?'.$this->get_query() : '');
    }

    /**
    * Get fragment
    *
    * Returns everything after the "#", or false if no fragment was specified
    * @return string
    */
    function get_fragment()
    {
        return (isset($this->fragment)) ? $this->fragment : false;
    }

    /**
    * Set URL parts
    * @param array $parts associative array containing URL parts to set 
    *                     (this will overwrite existing parts)
    * @access private
    * @return void
    */
    function _set_parts($parts)
    {
        $this->scheme   = (isset($parts['scheme'])   ? strtolower($parts['scheme']) : null);
        $this->user     = (isset($parts['user'])     ? $parts['user']               : null);
        $this->pass     = (isset($parts['pass'])     ? $parts['pass']               : null);
        $this->host     = (isset($parts['host'])     ? $parts['host']               : null);
        $this->port     = (isset($parts['port'])     ? (int)$parts['port']          : null);
        $this->path     = (isset($parts['path'])     ? $parts['path']               : '');
        $this->query    = (isset($parts['query'])    ? $parts['query']              : null);
        $this->fragment = (isset($parts['fragment']) ? $parts['fragment']           : null);
    }

    /**
    * Parse URL
    *
    * Regular expression grabbed from RFC 2396 Appendix B. 
    * This is a replacement for PHPs builtin parse_url().
    * @param string $url
    * @access private
    * @return array
    */
    function _parse_url($url)
    {
        // I'm using this pattern instead of parse_url() as there's a few strings where parse_url() 
        // generates a warning.
        if (preg_match('!^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?!', $url, $match)) {
            $parts = array();
            if ($match[1] != '') $parts['scheme'] = $match[2];
            if ($match[3] != '') $parts['auth'] = $match[4];
            // parse auth
            if (isset($parts['auth'])) {
                // store user info
                if (($at_pos = strpos($parts['auth'], '@')) !== false) {
                    $userinfo = explode(':', substr($parts['auth'], 0, $at_pos), 2);
                    $parts['user'] = $userinfo[0];
                    if (isset($userinfo[1])) $parts['pass'] = $userinfo[1];
                    $parts['auth'] = substr($parts['auth'], $at_pos+1);
                }
                // get port number
                if ($port_pos = strrpos($parts['auth'], ':')) {
                    $parts['host'] = substr($parts['auth'], 0, $port_pos);
                    $parts['port'] = (int)substr($parts['auth'], $port_pos+1);
                    if ($parts['port'] < 1) $parts['port'] = null;
                } else {
                    $parts['host'] = $parts['auth'];
                }
            }
            unset($parts['auth']);
            $parts['path'] = $match[5];
            if (isset($match[6]) && ($match[6] != '')) $parts['query'] = $match[7];
            if (isset($match[8]) && ($match[8] != '')) $parts['fragment'] = $match[9];
            return $parts;
        }
        // shouldn't reach here
        return array('path'=>'');
    }

    /**
    * Encode string
    *
    * Will try to escape certain chars which are safe to escape, cannot do them all
    * as it's impossible to detect which characters the user intends to be escaped.
    * @param string $string
    * @access private
    * @return string
    */
    function _encode($string)
    {
        static $replace = array();
        if (!count($replace)) {
            $find = array(32, 34, 60, 62, 123, 124, 125, 91, 92, 93, 94, 96, 127);
            $find = array_merge(range(0, 31), $find);
            $find = array_map('chr', $find);
            foreach ($find as $char) {
                $replace[$char] = '%'.bin2hex($char);
            }
        }
        // escape control characters and a few other characters
        $encoded = strtr($string, $replace);
        // remove any character outside the hex range: 21 - 7E (see www.asciitable.com)
        return preg_replace('/[^\x21-\x7e]/', '', $encoded);
    }
}
?>
