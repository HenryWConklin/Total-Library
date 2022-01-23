def Settings(**kwargs):
    return {
            'flags': [
                '-x', 'c++', 
                '-std=c++17', 
                '-fPIC', 
                '-Wall', 
                '-I', './godot-cpp/godot-headers', 
                '-I', './godot-cpp/include', 
                '-I', './godot-cpp/include/core', 
                '-I', './godot-cpp/include/gen', 
                '-I', './lib/boost', 
                '-I', './src']
            }
