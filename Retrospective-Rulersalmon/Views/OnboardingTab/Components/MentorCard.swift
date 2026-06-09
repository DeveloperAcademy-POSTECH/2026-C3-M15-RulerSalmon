//
//  MentorCard.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 6/1/26.
//

import SwiftUI

struct MentorCard: View {
    let mentor: Mentor
    let isSelected: Bool
    
    
    var body: some View {
        
        VStack(spacing: 16) {
            Image(mentor.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 220, height: 220)

            
            Text(mentor.name)
                .font(.system(size: 26))
                .fontWeight(.bold)
                .foregroundStyle(Color.blue500)
            
            Text(mentor.description)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(Color.gray600)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 10)
            
            HStack{
                ForEach(mentor.tags, id: \.self){ tag in
                    Text(tag)
                        .font(.footnote)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.blue500)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background {
                            Capsule()
                                .fill(Color.blue50)
                        }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background{
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.white)
        }
        .overlay{
            RoundedRectangle(cornerRadius: 30)
                .stroke(Color.gray300)
                .shadow(color: Color.gray, radius: 44)
        }
        .padding(.horizontal, 51)
        
    }
}

struct MentorCard_Previews: PreviewProvider {
    static var previews: some View {
        MentorCard(
            mentor: Mentor.sampleMentors[0],
            isSelected: true
        )
    }
}
