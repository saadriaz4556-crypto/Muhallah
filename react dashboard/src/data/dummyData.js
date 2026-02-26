export const users = [
    {
        id: 1,
        name: 'User 1',
        cnic: '35201-1234567-1',
        town: 'bahria',
        area: 'Block 13-A',
        status: 'Approved',
        phone: '0300-1234567',
        email: 'user1@email.com',
        profilePic: '/assets/user.jpg'
    },
    {
        id: 2,
        name: 'User 2',
        cnic: '35201-7654321-2',
        town: 'satellite',
        area: 'Block 14-B',
        status: 'Approved',
        phone: '0300-7654321',
        email: 'user2@email.com',
        profilePic: '/assets/user.jpg'
    },
    {
        id: 3,
        name: 'User 3',
        cnic: '35201-1122334-3',
        town: 'ghouri',
        area: 'Phase 5',
        status: 'Approved',
        phone: '0300-1122334',
        email: 'user3@email.com',
        profilePic: '/assets/user.jpg'
    },
    {
        id: 4,
        name: 'User 4',
        cnic: '35201-4455667-4',
        town: 'bahria',
        area: 'Block 2-C',
        status: 'Approved',
        phone: '0300-4455667',
        email: 'user4@email.com',
        profilePic: '/assets/user.jpg'
    },
    {
        id: 5,
        name: 'User 5',
        cnic: '35201-9988776-5',
        town: 'satellite',
        area: 'Block L-4',
        status: 'Approved',
        phone: '0300-9988776',
        email: 'user5@email.com',
        profilePic: '/assets/user.jpg'
    },
    {
        id: 6,
        name: 'User 6',
        cnic: '35201-5566778-6',
        town: 'ghouri',
        area: 'Sector C-2',
        status: 'Approved',
        phone: '0300-5566778',
        email: 'user6@email.com',
        profilePic: '/assets/user.jpg'
    },
    {
        id: 7,
        name: 'User 7',
        cnic: '12345-1234567-0',
        town: 'bahria',
        area: 'Block 13-A',
        status: 'Pending',
        phone: '+92 300 1234567',
        email: 'user7@email.com',
        profilePic: '/assets/user.jpg'
    },
    {
        id: 8,
        name: 'User 8',
        cnic: '12345-1234567-6',
        town: 'satellite',
        area: 'Block 14-B',
        status: 'Pending',
        phone: '+92 300 1234567',
        email: 'user8@email.com',
        profilePic: '/assets/user.jpg'
    }
];

export const announcements = [
    {
        id: 1,
        title: 'Water Supply Maintenance',
        content: 'Water supply will be temporarily suspended from 10 AM to 2 PM tomorrow for maintenance work. Please store water accordingly.',
        category: 'maintenance',
        priority: 'high',
        date: '2024-02-15',
        views: 142,
        attachments: 0,
        status: 'active'
    },
    {
        id: 2,
        title: 'Community Clean-up Drive',
        content: 'Join us for a community clean-up drive this Saturday. Together we can make our neighborhood cleaner and greener!',
        category: 'event',
        priority: 'medium',
        date: '2024-02-10',
        views: 89,
        attachments: 1,
        status: 'active'
    }
];

export const services = [
    {
        id: 1,
        name: 'Electrical Repair',
        category: 'electrical',
        person: 'Ahmed Raza',
        phone: '0300-1234567',
        description: 'Professional electrical services including wiring, repairs, and installations. Available 24/7 for emergencies.',
        descriptionText: 'Professional electrical services including wiring, repairs, and installations. Available 24/7 for emergencies.',
        image: '/assets/electrical.jpg',
        userId: 1,
        userTown: 'bahria',
        userArea: 'Block 13-A',
        availability: ['24/7', 'weekdays', 'weekends']
    },
    {
        id: 2,
        name: 'Plumbing Services',
        category: 'plumbing',
        person: 'Bilal Khan',
        phone: '0300-7654321',
        description: 'Expert plumbing solutions for leaks, installations, and maintenance. Quick response time guaranteed.',
        descriptionText: 'Expert plumbing solutions for leaks, installations, and maintenance. Quick response time guaranteed.',
        image: '/assets/plumbing.jpg',
        userId: 2,
        userTown: 'satellite',
        userArea: 'Block 14-B',
        availability: ['weekdays', 'weekends']
    },
    {
        id: 3,
        name: 'Home Cleaning',
        category: 'cleaning',
        person: 'Fatima Ali',
        phone: '0300-1122334',
        description: 'Thorough home cleaning services with eco-friendly products. Regular and one-time cleaning available.',
        descriptionText: 'Thorough home cleaning services with eco-friendly products. Regular and one-time cleaning available.',
        image: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=500&q=80',
        userId: 3,
        userTown: 'ghouri',
        userArea: 'Phase 5',
        availability: ['weekdays']
    }
];

export const complaints = [
    {
        id: 1,
        user: 'User 1',
        title: 'Broken Street Light',
        content: 'The street light near Block A has been not working for the past 3 days. It creates safety issues at night.',
        status: 'Pending',
        date: '2024-02-01',
        image: '/assets/broken-light-1.jpg'
    },
    {
        id: 2,
        user: 'User 2',
        title: 'Garbage Not Collected',
        content: 'The garbage from our street has not been collected for 5 days. It is creating bad smell and hygiene issues.',
        status: 'Pending',
        date: '2024-02-03',
        image: '/assets/garbage.jpg'
    },
    {
        id: 3,
        user: 'User 3',
        title: 'Water Pipeline Leakage',
        content: 'There is a major water leakage near house no. 45. A lot of water is being wasted and the road has become slippery.',
        status: 'Resolved',
        date: '2024-01-28',
        image: '/assets/water-leakeage.jpg'
    },
    {
        id: 4,
        user: 'User 4',
        title: 'Park Maintenance Needed',
        content: 'The children play area in the community park needs maintenance. Swings are broken and grass is overgrown.',
        status: 'Pending',
        date: '2024-02-05',
        image: '/assets/park-maintenance.jpg'
    }
];

export const marketplace = [
    {
        id: 1,
        title: 'Samsung LED',
        price: 'PKR 45,000',
        description: 'Almost new Samsung LED. Used for only 6 months. Excellent condition.',
        date: '2024-02-02',
        image: '/assets/samsung-led.jpg'
    },
    {
        id: 2,
        title: 'Office Desk',
        price: 'PKR 8,500',
        description: 'Wooden office desk in perfect condition. Size: 5x2.5 feet. Two drawers included.',
        date: '2024-02-04',
        image: 'https://images.unsplash.com/photo-1497366754035-f200968a6e72?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=500&q=80'
    },
    {
        id: 3,
        title: 'iPhone 12 Pro',
        price: 'PKR 85,000',
        description: 'iPhone 12 Pro 128GB in excellent condition. Includes original box and charger. No scratches.',
        date: '2024-02-01',
        image: 'https://images.unsplash.com/photo-1592899677977-9c10ca588bbd?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=500&q=80'
    }
];
